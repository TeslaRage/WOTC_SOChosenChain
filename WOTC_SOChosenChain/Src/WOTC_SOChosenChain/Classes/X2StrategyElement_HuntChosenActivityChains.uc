class X2StrategyElement_HuntChosenActivityChains extends X2StrategyElement_DefaultActivityChains;

var config(ChosenChain) bool bPlotGateCA2and3;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Activites;

	// All these chains are spawned via X2EventListener_ChosenChain
	Activites.AddItem(CreateHuntChosenTemplate());
	Activites.AddItem(CreateHuntChosenTemplate_Uno());
	Activites.AddItem(CreateHuntChosenTemplate_Dos());
	Activites.AddItem(CreateHuntChosenTemplate_Tres());

	return Activites;
}

static function X2DataTemplate CreateHuntChosenTemplate()
{
	local X2ActivityChainTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ActivityChainTemplate', Template, 'ActivityChain_HuntChosen');

	Template.SpawnInDeck = false;
	Template.NumInDeck = 1;
	Template.DeckReq = UseCustomSpawn;
	Template.bAllowComplications = false;

	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenMovements'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_HCSupplyConvoy'));
	if (default.bPlotGateCA2and3) Template.Stages.AddItem(ConstructPresetStage('Activity_WaitForPlot1'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenStrengths'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_HCIntelligenceInfiltrate'));
	if (default.bPlotGateCA2and3) Template.Stages.AddItem(ConstructPresetStage('Activity_WaitForPlot2'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenStronghold'));

	Template.GetOverviewDescription = HuntChosenGetOverviewDescription;
	Template.GetNarrativeObjective = HuntChosenGetNarrativeObjective;

	return Template;
}

static function X2DataTemplate CreateHuntChosenTemplate_Uno()
{
	local X2ActivityChainTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ActivityChainTemplate', Template, 'ActivityChain_HuntChosen_Uno');

	Template.SpawnInDeck = false;
	Template.NumInDeck = 1;
	Template.DeckReq = UseCustomSpawn;
	Template.bAllowComplications = false;

	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenMovements'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_HCIntelligenceInfiltrate'));
	if (default.bPlotGateCA2and3) Template.Stages.AddItem(ConstructPresetStage('Activity_WaitForPlot1'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenStrengths'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_HCSupplyConvoy'));
	if (default.bPlotGateCA2and3) Template.Stages.AddItem(ConstructPresetStage('Activity_WaitForPlot2'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenStronghold'));
	
	Template.GetOverviewDescription = HuntChosenGetOverviewDescription;
	Template.GetNarrativeObjective = HuntChosenGetNarrativeObjective;

	return Template;
}

static function X2DataTemplate CreateHuntChosenTemplate_Dos()
{
	local X2ActivityChainTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ActivityChainTemplate', Template, 'ActivityChain_HuntChosen_Dos');

	Template.SpawnInDeck = false;
	Template.NumInDeck = 1;
	Template.DeckReq = UseCustomSpawn;
	Template.bAllowComplications = false;

	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenMovements'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_HCIntelligenceInfiltrate'));
	if (default.bPlotGateCA2and3) Template.Stages.AddItem(ConstructPresetStage('Activity_WaitForPlot1'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenStrengths'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_HCRescueScientist'));
	if (default.bPlotGateCA2and3) Template.Stages.AddItem(ConstructPresetStage('Activity_WaitForPlot2'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenStronghold'));

	Template.GetOverviewDescription = HuntChosenGetOverviewDescription;
	Template.GetNarrativeObjective = HuntChosenGetNarrativeObjective;

	return Template;
}

static function X2DataTemplate CreateHuntChosenTemplate_Tres()
{
	local X2ActivityChainTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ActivityChainTemplate', Template, 'ActivityChain_HuntChosen_Tres');

	Template.SpawnInDeck = false;
	Template.NumInDeck = 1;
	Template.DeckReq = UseCustomSpawn;
	Template.bAllowComplications = false;

	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenMovements'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_HCIntelligenceInfiltrate'));
	if (default.bPlotGateCA2and3) Template.Stages.AddItem(ConstructPresetStage('Activity_WaitForPlot1'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenStrengths'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_HCRescueEngineer'));
	if (default.bPlotGateCA2and3) Template.Stages.AddItem(ConstructPresetStage('Activity_WaitForPlot2'));
	Template.Stages.AddItem(ConstructPresetStage('Activity_RevealChosenStronghold'));
	
	Template.GetOverviewDescription = HuntChosenGetOverviewDescription;
	Template.GetNarrativeObjective = HuntChosenGetNarrativeObjective;

	return Template;
}

static function bool UseCustomSpawn (XComGameState NewGameState)
{
	return false;
}

static function string HuntChosenGetOverviewDescription (XComGameState_ActivityChain ChainState)
{
	local XGParamTag kTag;
	local XComGameState_ResistanceFaction ResFaction;

	ResFaction = XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(ChainState.FactionRef.ObjectID));

	if (ResFaction == none)
	{
		`RedScreen("SOChosenChain: ResFaction is None");
	}

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = ResFaction.GetRivalChosen().GetChosenClassName();
	
	return `XEXPAND.ExpandString(ChainState.GetMyTemplate().strDescription);
}

static function string HuntChosenGetNarrativeObjective (XComGameState_ActivityChain ChainState)
{
	return ChainState.GetMyTemplate().strObjective;
}
