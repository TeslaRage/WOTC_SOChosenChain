class X2EventListener_ChosenChain extends X2EventListener config (ChosenChain);

var config bool bLog;
var config array<ActivitiesPlots> PlotGatedActivities;
var config array<ChosenChain> arrChosenChains;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateStrategyListeners());

	return Templates;
}

static function CHEventListenerTemplate CreateStrategyListeners()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'SpawnChosenChain');

	Template.AddCHEvent('PostEndOfMonth', PostEndOfMonth, ELD_OnStateSubmitted, 98);
	Template.AddCHEvent('OverrideAddChosenTacticalTagsToMission', OverrideAddChosenTacticalTagsToMission, ELD_Immediate, 100);
	Template.AddCHEvent('ShouldCleanupCovertAction', ShouldCleanupCovertAction, ELD_Immediate, 98);
	Template.RegisterInStrategy = true;

	return Template;
}

static protected function EventListenerReturn ShouldCleanupCovertAction(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{	
	local XComGameState_CovertAction Action, InfilAction;
	local XComLWTuple Tuple;
	local XComGameState_ActivityChain ChainState;
	local XComGameState_Activity ActivityState;
	local X2ActivityTemplate_CovertAction ActivityTemplate;
	local X2ActivityTemplate_Infiltration ActivityInfilTemplate;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none || Tuple.Id != 'ShouldCleanupCovertAction') return ELR_NoInterrupt;

	Action = XComGameState_CovertAction(Tuple.Data[0].o);

	`LOG("Action " $Action.GetMyTemplateName(), default.bLog, 'SOChosenChain');

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ActivityChain', ChainState)
	{
		if (class'X2DLCInfo_SOChosenChain'.static.IsChosenChain(ChainState.GetMyTemplateName()) && !ChainState.bEnded)
		{
			ActivityState = ChainState.GetCurrentActivity();
			ActivityTemplate = X2ActivityTemplate_CovertAction(ActivityState.GetMyTemplate());

			// Our CA activities
			if (ActivityState != none && ActivityTemplate != none && !ActivityTemplate.bExpires && ActivityTemplate.CovertActionName == Action.GetMyTemplateName())
			{
				Tuple.Data[1].b = false;
				`LOG("Action " $Action.GetMyTemplateName() $" for " $ChainState.GetMyTemplateName() $" (CA Activity) blocked from cleanup", default.bLog, 'SOChosenChain');
				break;
			}

			// Our Infiltration activities
			ActivityInfilTemplate = X2ActivityTemplate_Infiltration(ActivityState.GetMyTemplate());
			
			if (ActivityState != none && ActivityInfilTemplate != none && !ActivityInfilTemplate.bExpires)
			{
				InfilAction = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(ActivityState.SecondaryObjectRef.ObjectID));

				if (InfilAction != none && InfilAction.GetMyTemplateName() == Action.GetMyTemplateName())
				{
					Tuple.Data[1].b = false;
					`LOG("Action " $Action.GetMyTemplateName() $" for " $ChainState.GetMyTemplateName() $" (Infil Activity) blocked from cleanup", default.bLog, 'SOChosenChain');
					break;
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn PostEndOfMonth (Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SOChosenChain: Generate Chains for Met Chosens and Progress Wait Plots");
	SpawnChosenChains(NewGameState);
	CheckForPlotGates(NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	return ELR_NoInterrupt;
}

static function SpawnChosenChains (XComGameState NewGameState)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_ResistanceFaction ResFaction;
	local StateObjectReference FactionRef, SelectedRegion;
	local X2StrategyElementTemplateManager TemplateManager;
	local X2ActivityChainTemplate ChainTemplate;
	local XComGameState_ActivityChain ChainState;
	local array<StateObjectReference> RegionRefs;
	local XComGameState_AdventChosen RivalChosen;
	
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	foreach ResHQ.Factions(FactionRef)
	{
		ResFaction = XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(FactionRef.ObjectID));
		RivalChosen =  XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(ResFaction.RivalChosen.ObjectID));
		
		if (ResFaction == none || RivalChosen == none)
		{
			`RedScreen("SOChosenChain: ResFaction and/or RivalChosen are None");
			continue;
		}

		if (RivalChosen.IsStrongholdMissionAvailable())
		{
			`LOG("Chosen" @RivalChosen.GetChosenClassName() @"Stronghold mission is already available. Aborting.", default.bLog, 'SOChosenChain');
			continue;
		}

		if (RivalChosen.bMetXCom && ResFaction.bMetXCom && !ExistingChainAvailable(FactionRef) && !RivalChosen.bDefeated)
		{
			
			ChainTemplate = X2ActivityChainTemplate(TemplateManager.FindStrategyElementTemplate(GetChainByChosenTemplateName(RivalChosen.GetMyTemplateName())));
			RegionRefs = RivalChosen.TerritoryRegions;
			SelectedRegion = RegionRefs[`SYNC_RAND_STATIC(RegionRefs.Length)];

			ChainState = ChainTemplate.CreateInstanceFromTemplate(NewGameState);
			ChainState.FactionRef = FactionRef;
			ChainState.PrimaryRegionRef = SelectedRegion;
			ChainState.SecondaryRegionRef = SelectedRegion;
			ChainState.StartNextStage(NewGameState);
		}
	}
}

static function CheckForPlotGates (XComGameState NewGameState)
{
	local XComGameState_ActivityChain ChainState;
	local XComGameState_Activity_Wait WaitActivityState;
	local ActivitiesPlots PlotGatedActivity;
	local bool bProgressChain;
	local name ObjectiveName;
	
	// NewGameState is not checked here because activity's SetupStage is will complete itself if the plotobjectives are met
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ActivityChain', ChainState)
	{
		if (class'X2DLCInfo_SOChosenChain'.static.IsChosenChain(ChainState.GetMyTemplateName()) && !ChainState.bEnded)
		{
			bProgressChain = false; // Init
			foreach default.PlotGatedActivities(PlotGatedActivity)
			{
				if (ChainState.GetCurrentActivity().GetMyTemplateName() == PlotGatedActivity.ActivityName)
				{
					WaitActivityState = XComGameState_Activity_Wait(ChainState.GetCurrentActivity());
					foreach PlotGatedActivity.ObjectiveNames(ObjectiveName)
					{
						if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted(ObjectiveName)) 
						{
							bProgressChain = true;
							break; // If any objective in the array has been completed, we will progress the chain
						}
					}
					if (bProgressChain) break;
				}
			}

			if (bProgressChain)
			{
				WaitActivityState = XComGameState_Activity_Wait(NewGameState.ModifyStateObject(class'XComGameState_Activity_Wait', WaitActivityState.GetReference().ObjectID));
				WaitActivityState.ProgressAt = `STRATEGYRULES.GameTime;
			}
		}
	}
}

static function bool ExistingChainAvailable (StateObjectReference FactionRef)
{
	local XComGameState_ActivityChain ChainState;
	
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ActivityChain', ChainState)
	{
		if (class'X2DLCInfo_SOChosenChain'.static.IsChosenChain(ChainState.GetMyTemplateName()) && !ChainState.bEnded && ChainState.FactionRef == FactionRef)
		{
			return true;
		}
	}
	
	return false;
}

static protected function EventListenerReturn OverrideAddChosenTacticalTagsToMission (Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComGameState_AdventChosen ChosenState, LocalChosenState;
	local array<XComGameState_AdventChosen> AllChosen;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionSite MissionState;
	local name ChosenSpawningTag;
	local XComLWTuple Tuple;
	local XComGameState_Activity ActivityState;
	local XComGameState_ActivityChain ChainState;
	local bool bOurActivity;

	`LOG("Start OverrideAddChosenTacticalTagsToMission()", default.bLog, 'SOChosenChain');
	MissionState = XComGameState_MissionSite(EventSource);
	Tuple = XComLWTuple(EventData);

	if (MissionState == none || Tuple == none || NewGameState == none) return ELR_NoInterrupt;
	
	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	AllChosen = AlienHQ.GetAllChosen(NewGameState);

	// Get the actual pending mission state
	MissionState = XComGameState_MissionSite(NewGameState.GetGameStateForObjectID(MissionState.ObjectID));

	// If another mod already did something, skip our logic
	`LOG("TupleDatab: " $ Tuple.Data[0].b, default.bLog, 'SOChosenChain');
	if (Tuple.Data[0].b) return ELR_NoInterrupt;

	// We only want to mess with the mission related to our assault activity which normally can spawn Chosen, but we want to guarantee it
	// This activity is part of a chain that can only be spawned if XCOM has met Faction and its rival Chosen
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Activity', ActivityState)
	{
		if (class'X2DLCInfo_SOChosenChain'.static.IsChosenGuaranteedActivities(ActivityState.GetMyTemplateName()) && ActivityState.PrimaryObjectRef == MissionState.GetReference())
		{
			ChainState = XComGameState_ActivityChain(`XCOMHISTORY.GetGameStateForObjectID(ActivityState.ChainRef.ObjectID));

			if (ChainState != none && !ChainState.bEnded) bOurActivity = true;
		}
	}

	`LOG("bOurActivity: " $ bOurActivity, default.bLog, 'SOChosenChain');
	if (!bOurActivity) return ELR_NoInterrupt;

	// OK this mission is ours
	Tuple.Data[0].b = true;

	// First, remove tags of dead chosen and find the one that controls our region
	foreach AllChosen(ChosenState)
	{
		if (ChosenState.ChosenControlsRegion(MissionState.Region))
		{
			LocalChosenState = ChosenState;
		}
	}

	// Check if we found someone who can appear here
	`LOG("Chosen: " $ LocalChosenState.GetChosenClassName(), default.bLog, 'SOChosenChain');
	if (LocalChosenState == none) return ELR_NoInterrupt;
	
	ChosenSpawningTag = LocalChosenState.GetMyTemplate().GetSpawningTag(LocalChosenState.Level);

	// Check if the chosen is already scheduled to spawn
	if (MissionState.TacticalGameplayTags.Find(ChosenSpawningTag) != INDEX_NONE)
	{
		`LOG("Chosen is already scheduled to spawn here", default.bLog, 'SOChosenChain');
		return ELR_NoInterrupt;
	}

	`LOG("ChosenSpawningTag: " $ ChosenSpawningTag, default.bLog, 'SOChosenChain');
	MissionState.TacticalGameplayTags.AddItem(ChosenSpawningTag);

	`LOG("At end of OverrideAddChosenTacticalTagsToMission()", default.bLog, 'SOChosenChain');
	// We are finally done
	return ELR_NoInterrupt;
}

static function name GetChainByChosenTemplateName(name ChosenTemplateName)
{
	// This can become a problem because chosen template name is a config array in base game GameData
	// [XComGame.X2StrategyElement_DefaultAdventChosen]
	// Chosen=Chosen_Assassin
	// Chosen=Chosen_Hunter
	// Chosen=Chosen_Warlock

	if (default.arrChosenChains.Find('ChosenTemplateName', ChosenTemplateName) == INDEX_NONE)
	{
		`RedScreen("SOChosenChain: Critical X2EventListener_ChosenChain.default.arrChosenChain config error!");
		return 'ActivityChain_HuntChosen_Uno'; // You get just that one type
	}

	return default.arrChosenChains[default.arrChosenChains.Find('ChosenTemplateName', ChosenTemplateName)].ChainName;
}
