class X2DLCInfo_SOChosenChain extends X2DownloadableContentInfo;

var array<name> ChosenChainNames;
var array<name> ChosenGuaranteedActivities;

struct ActivitiesPlots
{
    var name ActivityName;
    var array<name> ObjectiveNames;
};

struct ChosenChain
{
    var name ChosenTemplateName;
    var name ChainName;    
};

static function OnPostTemplatesCreated()
{
    UpdateDefaultChosenCovertActions();
    UpdateDefaultRewards();
}

static function UpdateDefaultChosenCovertActions()
{
    local X2StrategyElementTemplateManager StratTemplateManager;    
    local X2ActivityTemplate_CovertAction ActivityCovertActionTemplate;
    local X2CovertActionTemplate CovertActionTemplate;    

    StratTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();    
    ActivityCovertActionTemplate = X2ActivityTemplate_CovertAction(StratTemplateManager.FindStrategyElementTemplate('Activity_RevealChosenMovements'));
    CovertActionTemplate = X2CovertActionTemplate(StratTemplateManager.FindStrategyElementTemplate('CovertAction_RevealChosenMovements'));

    if (ActivityCovertActionTemplate != none && CovertActionTemplate != none)
    {
        ActivityCovertActionTemplate.CovertActionName = CovertActionTemplate.DataName;
        CovertActionTemplate.bGoldenPath = false;
    }    

    ActivityCovertActionTemplate = X2ActivityTemplate_CovertAction(StratTemplateManager.FindStrategyElementTemplate('Activity_RevealChosenStrengths'));
    CovertActionTemplate = X2CovertActionTemplate(StratTemplateManager.FindStrategyElementTemplate('CovertAction_RevealChosenStrengths'));

    if (ActivityCovertActionTemplate != none && CovertActionTemplate != none)
    {
        ActivityCovertActionTemplate.CovertActionName = CovertActionTemplate.DataName;  
        CovertActionTemplate.bGoldenPath = false;
    }    

    ActivityCovertActionTemplate = X2ActivityTemplate_CovertAction(StratTemplateManager.FindStrategyElementTemplate('Activity_RevealChosenStronghold'));
    CovertActionTemplate = X2CovertActionTemplate(StratTemplateManager.FindStrategyElementTemplate('CovertAction_RevealChosenStronghold'));

    if (ActivityCovertActionTemplate != none && CovertActionTemplate != none)
    {
        ActivityCovertActionTemplate.CovertActionName = CovertActionTemplate.DataName;
        CovertActionTemplate.bGoldenPath = false;
    }
}

static function UpdateDefaultRewards()
{
    local X2StrategyElementTemplateManager StratTemplateManager;
    local X2RewardTemplate RewardTemplate;

    StratTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

    RewardTemplate = X2RewardTemplate(StratTemplateManager.FindStrategyElementTemplate('Reward_FactionInfluence'));

    if (RewardTemplate != none)
    {
        RewardTemplate.GiveRewardFn = GiveFactionInfluenceRewardWithBlock;
    }

    RewardTemplate = X2RewardTemplate(StratTemplateManager.FindStrategyElementTemplate('Reward_RevealStronghold'));

    if (RewardTemplate != none)
    {
        RewardTemplate.GiveRewardFn = GiveRevealStrongholdRewardWithBlock;
    }
}

static function GiveFactionInfluenceRewardWithBlock(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_CovertAction ActionState;
	local XComGameState_ResistanceFaction FactionState;

    `LOG("GiveFactionInfluenceRewardWithBlock: Start", class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');
    ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));	    
    FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', ActionState.Faction.ObjectID));
	
    // This had to be done because players may fail the chain so repeated chain will not give faction influence
    if (FactionState.GetInfluence() == eFactionInfluence_Minimal)
    {
        `LOG("GiveFactionInfluenceRewardWithBlock: Faction influence given.", class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');        
        FactionState.IncreaseInfluenceLevel(NewGameState);
    }
}

static function GiveRevealStrongholdRewardWithBlock(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_CovertAction ActionState;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_AdventChosen ChosenState;

    `LOG("GiveRevealStrongholdRewardWithBlock: Start", class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');	
	ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
    FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', ActionState.Faction.ObjectID));

    // This had to be done because players may fail the chain so repeated chain will not give faction influence
    if (FactionState.GetInfluence() == eFactionInfluence_Respected)
    {
        // Increase influence with the Faction
        `LOG("GiveRevealStrongholdRewardWithBlock: Faction influence given.", class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');        
        FactionState.IncreaseInfluenceLevel(NewGameState);
    }

	// Then reveal the Stronghold mission
	ChosenState = ActionState.GetFaction().GetRivalChosen();
	ChosenState.MakeStrongholdMissionVisible(NewGameState);
}

static function array<name> GetObjectivesForActivity (XComGameState_Activity ActivityState)
{
    local ActivitiesPlots PlotGatedActivity;    

    foreach class'X2EventListener_ChosenChain'.default.PlotGatedActivities(PlotGatedActivity)
    {
        if (PlotGatedActivity.ActivityName == ActivityState.GetMyTemplateName())
        {            
            return PlotGatedActivity.ObjectiveNames;
        }
    }

    PlotGatedActivity.ObjectiveNames.Length = 0;
    return PlotGatedActivity.ObjectiveNames;
}

static function bool IsChosenChain(name ChainName)
{
    if (default.ChosenChainNames.Find(ChainName) == INDEX_NONE) return false;
    return true;
}

static function bool IsChosenGuaranteedActivities(name ActivityName)
{
    if (default.ChosenGuaranteedActivities.Find(ActivityName) == INDEX_NONE) return false;
    return true;
}

static function XComGameState_AdventChosen GetChosenState(name ChosenName, out StateObjectReference FactionRef)
{
	local XComGameState_AdventChosen Chosen;
	local XComGameState_ResistanceFaction ResFaction;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AdventChosen', Chosen)
	{
		ResFaction = XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(Chosen.RivalFaction.ObjectID));
		FactionRef = ResFaction.GetReference();

		if (Chosen.GetMyTemplateName() == ChosenName && Chosen.bMetXCom && !Chosen.bDefeated && ResFaction.bMetXCom)
		{
			return Chosen;
		}
	}

	return none;
}

// The content is copied from XComGameState_ActivityChain::DoRemove
exec function ChosenChain_RemoveAllChains ()
{
    local XComGameState_ActivityChain ChainState, NewChainState;
    local XComGameState NewGameState;
    local StateObjectReference ActivityRef, ComplicationRef;
    local XComGameState_Activity ActivityState;
    local XComGameState_Complication ComplicationState;

    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ActivityChain', ChainState)
    {        
        if (IsChosenChain(ChainState.GetMyTemplateName()) && !ChainState.bEnded)
        {
            `LOG("RemoveAllChosenChain: Attempt removal of chain " $ChainState.GetMyTemplateName(), class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');

            NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SOChosenChain: Removing" @ ChainState.GetMyTemplateName());
            NewChainState = XComGameState_ActivityChain(NewGameState.ModifyStateObject(class'XComGameState_ActivityChain', ChainState.ObjectID));

            if (ChainState.GetMyTemplate().RemoveChain != none) ChainState.GetMyTemplate().RemoveChain(NewGameState, NewChainState);

            foreach ChainState.StageRefs(ActivityRef)
            {
                ActivityState = XComGameState_Activity(NewGameState.ModifyStateObject(class'XComGameState_Activity', ActivityRef.ObjectID));
                ActivityState.RemoveEntity(NewGameState);
            }

            foreach ChainState.ComplicationRefs(ComplicationRef)
            {
                ComplicationState = XComGameState_Complication(NewGameState.ModifyStateObject(class'XComGameState_Complication', ComplicationRef.ObjectID));
                ComplicationState.RemoveComplication(NewGameState);
            }

            if (ChainState.GetMyTemplate().RemoveChainLate != none) ChainState.GetMyTemplate().RemoveChainLate(NewGameState, NewChainState);

            NewGameState.RemoveStateObject(ChainState.ObjectID);
            `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

            `LOG("RemoveAllChosenChain: Completed removal of chain " $ChainState.GetMyTemplateName(), class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');
        }
    }
}

// The content is copied from XComGameState_ActivityChain::DoRemove
exec function ChosenChain_RemoveChain (name ChosenName)
{
	local XComGameState_ActivityChain ChainState, NewChainState;
	local XComGameState NewGameState;
	local StateObjectReference ActivityRef, ComplicationRef;
	local XComGameState_Activity ActivityState;
	local XComGameState_Complication ComplicationState;
	local XComGameState_AdventChosen RivalChosen;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_ActivityChain', ChainState)
	{		
		if (IsChosenChain(ChainState.GetMyTemplateName()) && !ChainState.bEnded)
		{
			`LOG("RemoveChosenChain: Attempt removal of chain " $ChainState.GetMyTemplateName(), class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');

			// Get rival chosen
			RivalChosen =  XComGameState_AdventChosen(History.GetGameStateForObjectID(
							XComGameState_ResistanceFaction(History.GetGameStateForObjectID(ChainState.FactionRef.ObjectID)).RivalChosen.ObjectID));

			// Only proceed if this is the chosen chain we want
			if (RivalChosen.GetMyTemplateName() != ChosenName) continue;

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SOChosenChain: Removing" @ ChainState.GetMyTemplateName());
			NewChainState = XComGameState_ActivityChain(NewGameState.ModifyStateObject(class'XComGameState_ActivityChain', ChainState.ObjectID));

			if (ChainState.GetMyTemplate().RemoveChain != none) ChainState.GetMyTemplate().RemoveChain(NewGameState, NewChainState);

			foreach ChainState.StageRefs(ActivityRef)
			{
				ActivityState = XComGameState_Activity(NewGameState.ModifyStateObject(class'XComGameState_Activity', ActivityRef.ObjectID));
				ActivityState.RemoveEntity(NewGameState);
			}

			foreach ChainState.ComplicationRefs(ComplicationRef)
			{
				ComplicationState = XComGameState_Complication(NewGameState.ModifyStateObject(class'XComGameState_Complication', ComplicationRef.ObjectID));
				ComplicationState.RemoveComplication(NewGameState);
			}

			if (ChainState.GetMyTemplate().RemoveChainLate != none) ChainState.GetMyTemplate().RemoveChainLate(NewGameState, NewChainState);

			NewGameState.RemoveStateObject(ChainState.ObjectID);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			`LOG("RemoveChosenChain: Completed removal of chain " $ChainState.GetMyTemplateName(), class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');
		}
	}
}

exec function ChosenChain_SpawnActivityChain (name ChosenName, int StartAtStage = 0)
{
	local X2StrategyElementTemplateManager TemplateManager;
	local XComGameState_ActivityChain ChainState;
	local X2ActivityChainTemplate ChainTemplate;
	local XComGameState NewGameState;
	local XComGameState_AdventChosen Chosen;
	local array<StateObjectReference> RegionRefs;
	local StateObjectReference FactionRef, SelectedRegion;

	Chosen = GetChosenState(ChosenName, FactionRef);
	if (Chosen == none) return;
	if (class'X2EventListener_ChosenChain'.static.ExistingChainAvailable(FactionRef)) return;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SpawnChosenActivityChain for" @ ChosenName);
	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ChainTemplate = X2ActivityChainTemplate(TemplateManager.FindStrategyElementTemplate(class'X2EventListener_ChosenChain'.static.GetChainByChosenTemplateName(Chosen.GetMyTemplateName())));

	ChainState = ChainTemplate.CreateInstanceFromTemplate(NewGameState);
	ChainState.HACK_SetCurrentStage(StartAtStage - 1);
	ChainState.HACK_SetStartedAt(class'XComGameState_GeoscapeEntity'.static.GetCurrentTime());

	// Chosen Chain specific parameters that need to be filled out
	ChainState.FactionRef = FactionRef;

	RegionRefs = Chosen.TerritoryRegions;
	SelectedRegion = RegionRefs[`SYNC_RAND_STATIC(RegionRefs.Length)];
	ChainState.PrimaryRegionRef = SelectedRegion;
	ChainState.SecondaryRegionRef = SelectedRegion;	

	// Start chain
	ChainState.StartNextStage(NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// To be used in cases where the activity wait does not move even when plot objectives have been completed
exec function ChosenChain_RemoveWaitStep ()
{
    local XComGameState_ActivityChain ChainState;
    local XComGameState NewGameState;
    local XComGameState_Activity_Wait WaitActivityState;
    
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ActivityChain', ChainState)
    {
        if (IsChosenChain(ChainState.GetMyTemplateName()) && !ChainState.bEnded &&
            (ChainState.GetCurrentActivity().GetMyTemplateName() == 'Activity_WaitForPlot1' || ChainState.GetCurrentActivity().GetMyTemplateName() == 'Activity_WaitForPlot2'))
        {
            NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SOChosenChain: Removing Wait Plots");

            WaitActivityState = XComGameState_Activity_Wait(ChainState.GetCurrentActivity());
            WaitActivityState = XComGameState_Activity_Wait(NewGameState.ModifyStateObject(class'XComGameState_Activity_Wait', WaitActivityState.ObjectID));
            WaitActivityState.ProgressAt = `STRATEGYRULES.GameTime;
            `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
        }
    }
}

exec function ChosenChain_PrintActivityGoldenPathStatus()
{
    local X2StrategyElementTemplateManager StratTemplateManager;        
    local X2CovertActionTemplate CovertActionTemplate;    

    StratTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
    CovertActionTemplate = X2CovertActionTemplate(StratTemplateManager.FindStrategyElementTemplate('CovertAction_RevealChosenMovements'));

    if (CovertActionTemplate != none)
    {
        `LOG(CovertActionTemplate.DataName $".bGoldenPath: " $CovertActionTemplate.bGoldenPath, true, 'SOChosenChain');
    }

    CovertActionTemplate = X2CovertActionTemplate(StratTemplateManager.FindStrategyElementTemplate('CovertAction_RevealChosenStrengths'));

    if (CovertActionTemplate != none)
    {
        `LOG(CovertActionTemplate.DataName $".bGoldenPath: " $CovertActionTemplate.bGoldenPath, true, 'SOChosenChain');
    }

    CovertActionTemplate = X2CovertActionTemplate(StratTemplateManager.FindStrategyElementTemplate('CovertAction_RevealChosenStronghold'));

    if (CovertActionTemplate != none)
    {
        `LOG(CovertActionTemplate.DataName $".bGoldenPath: " $CovertActionTemplate.bGoldenPath, true, 'SOChosenChain');
    }
}

DefaultProperties
{
    // Used for checks whether the chain is a Chosen Chain
    ChosenChainNames[0] = "ActivityChain_HuntChosen";
    ChosenChainNames[1] = "ActivityChain_HuntChosen_Uno";
    ChosenChainNames[2] = "ActivityChain_HuntChosen_Dos";
    ChosenChainNames[3] = "ActivityChain_HuntChosen_Tres";

    // Controls activities that have guaranteed chosen appearance
    ChosenGuaranteedActivities[0] = "Activity_HCSupplyConvoy";
    ChosenGuaranteedActivities[1] = "Activity_HCSecureUFO";
    ChosenGuaranteedActivities[2] = "Activity_HCRescueScientist";
    ChosenGuaranteedActivities[3] = "Activity_HCRescueEngineer";      
}