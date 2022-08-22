class X2StrategyElement_HuntChosenActivities extends X2StrategyElement_DefaultActivities;

var config int RescueDifficulty;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
		
	CreateActivity_RevealChosenMovements(Templates);
    CreateActivity_RevealChosenStrengths(Templates);
    CreateActivity_RevealChosenStronghold(Templates);
	CreateActivity_SupplyConvoy(Templates);
	CreateActivity_IntelligenceInfiltration(Templates);
	CreateActivity_WaitForPlot1(Templates);
	CreateActivity_WaitForPlot2(Templates);
	CreateActivity_SecureUFO(Templates);
	CreateActivity_RescueScientist(Templates);
	CreateActivity_RescueEngineer(Templates);

	return Templates;
}

//////////////////////
/// Covert Actions ///
//////////////////////

static function CreateActivity_RevealChosenMovements (out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate_CovertAction Activity;	
	
	`CREATE_X2TEMPLATE(class'X2ActivityTemplate_CovertAction', Activity, 'Activity_RevealChosenMovements');
    
	Activity.AvailableSound = "Geoscape_NewResistOpsMissions";
	Activity.RemoveStage = RemoveAssociatedStateObjects;
	
	Templates.AddItem(Activity);
}

static function CreateActivity_RevealChosenStrengths (out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate_CovertAction Activity;	
	
	`CREATE_X2TEMPLATE(class'X2ActivityTemplate_CovertAction', Activity, 'Activity_RevealChosenStrengths');
	    
	Activity.AvailableSound = "Geoscape_NewResistOpsMissions";
	Activity.RemoveStage = RemoveAssociatedStateObjects;
	
	Templates.AddItem(Activity);
}

static function CreateActivity_RevealChosenStronghold (out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate_CovertAction Activity;	
	
	`CREATE_X2TEMPLATE(class'X2ActivityTemplate_CovertAction', Activity, 'Activity_RevealChosenStronghold');
	    
	Activity.AvailableSound = "Geoscape_NewResistOpsMissions";
	Activity.RemoveStage = RemoveAssociatedStateObjects;
	
	Templates.AddItem(Activity);
}

/////////////////////////
/// Preset Activities ///
/////////////////////////

static function CreateActivity_SupplyConvoy(out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate_Assault Activity;

	`CREATE_X2TEMPLATE(class'X2ActivityTemplate_Assault', Activity, 'Activity_HCSupplyConvoy');
	
	Activity.OverworldMeshPath = "UI_3D.Overwold_Final.SupplyRaid_AdvConvoy";
	Activity.UIButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_SupplyRaid";
	Activity.MissionImage = "img:///UILibrary_StrategyImages.Alert_Supply_Raid";
	Activity.Difficulty = default.ConvoyDifficulty;
		
	Activity.MissionRewards.AddItem('Reward_Materiel');	
	Activity.GetMissionDifficulty = GetMissionDifficultyFromMonthPlusTemplate;
	Activity.WasMissionSuccessful = class'X2StrategyElement_DefaultMissionSources'.static.OneStrategyObjectiveCompleted;
	Activity.AvailableSound = "Geoscape_Supply_Raid_Popup";

	Activity.RemoveStage = RemoveAssociatedStateObjects;
	
	Templates.AddItem(Activity);
}

static function CreateActivity_IntelligenceInfiltration (out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate_Infiltration ActivityInfil;
	local X2CovertActionTemplate CovertAction;

	CovertAction = class'X2StrategyElement_InfiltrationActions'.static.CreateInfiltrationTemplate('CovertAction_HCIntelligenceInfiltrate', true);
	ActivityInfil = CreateStandardInfilActivity(CovertAction, "HCIntelligenceInfiltrate", "GeoscapeMesh_CI.CI_Geoscape.CI_HackDevice", "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_ResHQ");
	
	ActivityInfil.MissionRewards.AddItem('Reward_SmallIntel');
	ActivityInfil.GetMissionDifficulty = GetMissionDifficultyFromMonth;
	ActivityInfil.WasMissionSuccessful = class'X2StrategyElement_DefaultMissionSources'.static.OneStrategyObjectiveCompleted;
	ActivityInfil.AvailableSound = "Geoscape_NewResistOpsMissions";

	ActivityInfil.RemoveStage = RemoveAssociatedStateObjects;
	
	Templates.AddItem(CovertAction);
	Templates.AddItem(ActivityInfil);
}

static function CreateActivity_WaitForPlot1(out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate Activity;

	// This is a special "activity" which does nothing but waits for plot objectives to be completed
	
	`CREATE_X2TEMPLATE(class'X2ActivityTemplate', Activity, 'Activity_WaitForPlot1');
	
	Activity.ActivityType = 'eActivityType_WaitPlot';	
	Activity.StateClass = class'XComGameState_Activity_WaitPlot';
	Activity.GetOverviewStatus = WaitGetOverviewStatus;
	Activity.GetOverviewDescription = WaitPlotOverViewDescription;
	Activity.SetupStage = ProgressIfPlotDone;	

	Templates.AddItem(Activity);
}

static function CreateActivity_WaitForPlot2(out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate Activity;

	// This is a special "activity" which does nothing but waits for plot objectives to be completed
	
	`CREATE_X2TEMPLATE(class'X2ActivityTemplate', Activity, 'Activity_WaitForPlot2');
	
	Activity.ActivityType = 'eActivityType_WaitPlot';	
	Activity.StateClass = class'XComGameState_Activity_WaitPlot';
	Activity.GetOverviewStatus = WaitGetOverviewStatus;	
	Activity.GetOverviewDescription = WaitPlotOverViewDescription;
	Activity.SetupStage = ProgressIfPlotDone;	

	Templates.AddItem(Activity);
}

static function ProgressIfPlotDone (XComGameState NewGameState, XComGameState_Activity ActivityState)
{
	local bool bProgressChain;
	local ActivitiesPlots PlotGatedActivity;
	local XComGameState_Activity_Wait WaitActivityState;
	local name ObjectiveName;

	bProgressChain = false; // Init
	foreach class'X2EventListener_ChosenChain'.default.PlotGatedActivities(PlotGatedActivity)
	{	
		if (ActivityState.GetMyTemplateName() != PlotGatedActivity.ActivityName) continue;
		
		foreach PlotGatedActivity.ObjectiveNames(ObjectiveName)
		{
			if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted(ObjectiveName)) 
			{
				WaitActivityState = XComGameState_Activity_Wait(ActivityState);
				// No need to call NewGameState.ModifyStateObject here as SetupStage is passed an already modified state
				bProgressChain = true;
				break; // If any objective in the array has been completed, we will progress the chain
			}						
		}
		if (bProgressChain) break;		
	}

	if (bProgressChain)
	{		
		WaitActivityState.ProgressAt = `STRATEGYRULES.GameTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddTime(WaitActivityState.ProgressAt, 1);
	}
}

static function string WaitPlotOverViewDescription (XComGameState_Activity ActivityState)
{
	local XGParamTag kTag;
	local int idx;
	local X2StrategyElementTemplateManager StratMan;
	local X2ObjectiveTemplate ObjectiveTemplate;
	local ActivitiesPlots PlotGatedActivity;	

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	StratMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	foreach class'X2EventListener_ChosenChain'.default.PlotGatedActivities(PlotGatedActivity)
	{	
		if (PlotGatedActivity.ActivityName == ActivityState.GetMyTemplateName())
		{
			kTag.StrValue0 = "";			
			for (idx = 0; idx < PlotGatedActivity.ObjectiveNames.Length; idx++)
			{
				ObjectiveTemplate = X2ObjectiveTemplate(StratMan.FindStrategyElementTemplate(PlotGatedActivity.ObjectiveNames[idx]));				

				if (ObjectiveTemplate != none)
				{					
					if (idx < PlotGatedActivity.ObjectiveNames.Length - 1) kTag.StrValue0 $= ObjectiveTemplate.Title $" / ";
					else kTag.StrValue0 $= ObjectiveTemplate.Title;
				}
			}
		}
	}

	return `XEXPAND.ExpandString(ActivityState.GetMyTemplate().strOverviewDescription);
}

static function CreateActivity_SecureUFO(out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate_Assault Activity;
	
	`CREATE_X2TEMPLATE(class'X2ActivityTemplate_Assault', Activity, 'Activity_HCSecureUFO');
	
	Activity.OverworldMeshPath = "UI_3D.Overwold_Final.Landed_UFO";
	Activity.UIButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Advent";
	Activity.ScreenClass = class'UIMission_LandedUFO';
	Activity.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_UFO_Landed";
	Activity.Difficulty = default.LandedDifficulty;	
	
	Activity.MissionRewards.AddItem('Reward_Materiel');
	Activity.GetMissionDifficulty = GetMissionDifficultyFromMonthPlusTemplate;
	Activity.WasMissionSuccessful = class'X2StrategyElement_DefaultMissionSources'.static.OneStrategyObjectiveCompleted;
	Activity.AvailableSound = "Geoscape_UFO_Landed";

	Activity.RemoveStage = RemoveAssociatedStateObjects;

	Templates.AddItem(Activity);
}

static function CreateActivity_RescueScientist(out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate_Assault Activity;
	
	`CREATE_X2TEMPLATE(class'X2ActivityTemplate_Assault', Activity, 'Activity_HCRescueScientist');
	
	Activity.OverworldMeshPath = "UI_3D.Overwold_Final.Council_VIP";
	Activity.UIButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Council";
	Activity.ScreenClass = class'UIMission_ResOps';
	Activity.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Guerrilla_Ops";
	Activity.Difficulty = default.RescueDifficulty;
	
	Activity.MissionRewards.AddItem('Reward_Scientist');
	Activity.GetMissionDifficulty = GetMissionDifficultyFromMonthPlusTemplate;
	Activity.WasMissionSuccessful = class'X2StrategyElement_DefaultMissionSources'.static.OneStrategyObjectiveCompleted;
	Activity.AvailableSound = "Geoscape_NewResistOpsMissions";

	Activity.RemoveStage = RemoveAssociatedStateObjects;

	Templates.AddItem(Activity);
}

static function CreateActivity_RescueEngineer(out array<X2DataTemplate> Templates)
{
	local X2ActivityTemplate_Assault Activity;
	
	`CREATE_X2TEMPLATE(class'X2ActivityTemplate_Assault', Activity, 'Activity_HCRescueEngineer');
	
	Activity.OverworldMeshPath = "UI_3D.Overwold_Final.Council_VIP";
	Activity.UIButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Council";
	Activity.ScreenClass = class'UIMission_ResOps';
	Activity.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Guerrilla_Ops";
	Activity.Difficulty = default.RescueDifficulty;
	
	Activity.MissionRewards.AddItem('Reward_Engineer');
	Activity.GetMissionDifficulty = GetMissionDifficultyFromMonthPlusTemplate;
	Activity.WasMissionSuccessful = class'X2StrategyElement_DefaultMissionSources'.static.OneStrategyObjectiveCompleted;
	Activity.AvailableSound = "Geoscape_NewResistOpsMissions";

	Activity.RemoveStage = RemoveAssociatedStateObjects;

	Templates.AddItem(Activity);
}

/////////////////
/// Delegates ///
/////////////////

static function RemoveAssociatedStateObjects (XComGameState NewGameState, XComGameState_Activity ActivityState)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionSite;
	local XComGameState_CovertAction CovertAction;
	local XComGameState_MissionSiteInfiltration MissionSiteInfil;

	History = `XCOMHISTORY;

	// X2ActivityTemplate_Infiltration
	MissionSiteInfil = XComGameState_MissionSiteInfiltration(History.GetGameStateForObjectID(ActivityState.PrimaryObjectRef.ObjectID));
	if (MissionSiteInfil != none)
	{
		MissionSiteInfil.RemoveEntity(NewGameState);
	}

	CovertAction = XComGameState_CovertAction(History.GetGameStateForObjectID(ActivityState.SecondaryObjectRef.ObjectID));
	if (CovertAction != none)
	{
		CovertAction.RemoveEntity(NewGameState);
	}

	// X2ActivityTemplate_Assault
	MissionSite = XComGameState_MissionSite(History.GetGameStateForObjectID(ActivityState.PrimaryObjectRef.ObjectID));
	if (MissionSite != none)
	{
		MissionSite.RemoveEntity(NewGameState);
	}

	// X2ActivityTemplate_CovertAction
	CovertAction = XComGameState_CovertAction(History.GetGameStateForObjectID(ActivityState.PrimaryObjectRef.ObjectID));
	if (CovertAction != none)
	{
		CovertAction.RemoveEntity(NewGameState);
	}
}
