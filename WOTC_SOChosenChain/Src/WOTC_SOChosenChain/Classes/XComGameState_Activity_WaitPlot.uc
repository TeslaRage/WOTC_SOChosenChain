// The purpose of this state is just to handle event trigger ObjectiveCompleted triggered from XComGameState_Objective::CompleteObjective
class XComGameState_Activity_WaitPlot extends XComGameState_Activity_Wait;

////////////////
/// Creation ///
////////////////

event OnCreation (optional X2DataTemplate Template)
{
	local X2EventManager EventManager;
	local Object SelfObj;

	super.OnCreation(Template);

	EventManager = `XEVENTMGR;
	SelfObj = self;	

    EventManager.RegisterForEvent(SelfObj, 'ObjectiveCompleted', OnObjectiveCompleted, ELD_OnStateSubmitted, , , true, SelfObj);
}

///////////////////////
/// Event Listeners ///
///////////////////////

function EventListenerReturn OnObjectiveCompleted(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Activity ActivityState;
	local XComGameState_Objective ObjectiveState;
    local array<name> ObjectivesForActivity;
    local XComGameState NewGameState;
    local XComGameState_Activity_Wait WaitActivityState;

	`LOG("Entering XComGameState_Activity_WaitPlot::OnObjectiveCompleted", class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');

	ActivityState = XComGameState_Activity_WaitPlot(CallbackData);
	ObjectiveState = XComGameState_Objective(EventSource);

	if (ActivityState == none)
	{
		`LOG("CallbackData is not XComGameState_Activity", class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');
	}

	if (ObjectiveState == none)
	{
		`LOG("EventSource is not XComGameState_Objective", class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');
	}

	if (ObjectiveState == none && ActivityState == none) return ELR_NoInterrupt;

    if (ActivityState.CompletionStatus == eActivityCompletion_NotCompleted)
    {        
        ObjectivesForActivity = class'X2DLCInfo_SOChosenChain'.static.GetObjectivesForActivity(ActivityState);

        if (ObjectivesForActivity.Length == 0) return ELR_NoInterrupt;

        if (ObjectivesForActivity.Find(ObjectiveState.GetMyTemplateName()) == INDEX_NONE) return ELR_NoInterrupt;

        `LOG("Completing Wait Stage", class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');
        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SOChosenChain: Progressing Wait Plots");

        WaitActivityState = XComGameState_Activity_WaitPlot(NewGameState.ModifyStateObject(class'XComGameState_Activity_Wait', ActivityState.ObjectID));
        WaitActivityState.ProgressAt = `STRATEGYRULES.GameTime;
        `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
    }

	`LOG("ActivityState.GetMyTemplateName(): " $ActivityState.GetMyTemplateName(), class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');
	`LOG("ObjectiveState.GetMyTemplateName(): " $ObjectiveState.GetMyTemplateName(), class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');
	`LOG("End of XComGameState_Activity_WaitPlot::OnObjectiveCompleted", class'X2EventListener_ChosenChain'.default.bLog, 'SOChosenChain');

	return ELR_NoInterrupt;
}