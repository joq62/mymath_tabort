%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(mymath).   
-behaviour(gen_server).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
-define(SERVER,?MODULE).
%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state, {
	       refs}).



%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------

-export([
	 ping/0,
	 start/0,
	 stop/0
	]).

%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

%%-----------------------------------------------------------------------

%%----------------------------------------------------------------------
%% Gen server functions

start()-> gen_server:start_link(?SERVER, [], []).
stop()-> gen_server:call(?SERVER, {stop},infinity).


%%---------------------------------------------------------------
-spec ping()-> {atom(),node(),module()}|{atom(),term()}.
%% 
%% @doc:check if service is running
%% @param: non
%% @returns:{pong,node,module}|{badrpc,Reason}
%%
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: 
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%
%% --------------------------------------------------------------------
init([]) ->
    {ok,AddNode,AddPid}=loader:allocate(myadd),
    AddRef=erlang:monitor(process,AddPid),
    true=erlang:monitor_node(AddNode,true),
    io:format("AddNode,AddPid AddRef ~p~n",[{AddNode,AddPid,AddRef}]),
    {ok,DiviNode,DiviPid}=loader:allocate(mydivi),
    DiviRef=erlang:monitor(process,DiviPid),
    io:format("DiviNode,DiviPid,DiviRef ~p~n",[{DiviNode,DiviPid,DiviRef}]),
    true=erlang:monitor_node(DiviNode,true),
    
    
    {ok, #state{refs=[{AddNode,AddPid,AddRef,myadd},
		      {DiviNode,DiviPid,DiviRef,mydivi}]}}.
    
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (aterminate/2 is called)
%% --------------------------------------------------------------------
handle_call({ping},_From,State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply, State};

handle_call({stop}, _From, State) ->    
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% -------------------------------------------------------------------
    
handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({Pid,{mymath,stop,divi}}, State) ->
    io:format("stop ~p~n",[{?MODULE,?LINE}]),
    {Node,AppPid,_,_}=lists:keyfind(mydivi,4,State#state.refs),
    rpc:call(Node,erlang,exit,[AppPid,stopped]),
    Pid!{self(),ok},
    {noreply, State};

handle_info({Pid,{mymath,stop,add}}, State) ->
    io:format("stop ~p~n",[{?MODULE,?LINE}]),
    {Node,AppPid,_,_}=lists:keyfind(myadd,4,State#state.refs),
    rpc:call(Node,erlang,exit,[AppPid,stopped]),
    Pid!{self(),ok},
    {noreply, State};

handle_info({stop}, State) ->
    io:format("stop ~p~n",[{?MODULE,?LINE}]),
    exit(self(),normal),
    {noreply, State};

handle_info({Pid,{Module,Function,Args}}, State) ->
    io:format("~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,
		       Module,Function,Args}]),
    {Node,AppPid,_,_}=lists:keyfind(Module,4,State#state.refs),
    Result=case rpc:call(Node,erlang,is_process_alive,[AppPid],2000) of
	       false->
		   {error,[AppPid,is_not_alive]};
	       true->
		   lrpc(AppPid,Function,Args,10000)
	   end,
    Pid!{self(),Result},
    {noreply, State};

%%--------------------------------------------------------------

handle_info({nodedown,Node}, State) ->
    io:format("nodedown  ~p~n",[{Node}]),
    {noreply, State};

handle_info({'DOWN',Ref,Type,Pid,normal}, State) ->
    io:format("Down  ~p~n",[{Ref,Pid,Type,normal}]),
    {noreply, State};
handle_info({'DOWN',Ref,Type,Pid,Reason}, State) ->
    io:format("Down  ~p~n",[{Ref,Pid,Type,Reason, nodes()}]),
    {Node,AppPid,Ref,App}=lists:keyfind(Ref,3,State#state.refs),
    %loader:deallocate(Node,AppPid),
    erlang:monitor_node(Node,false),
    slave:stop(Node),
    true=erlang:demonitor(Ref),
    {ok,NewNode,NewPid}=loader:allocate(App),
    NewRef=erlang:monitor(process,NewPid),
    Refs=lists:delete({Node,AppPid,Ref,App},State#state.refs),
    io:format("Refs ~p~n",[Refs]),  
    io:format("State#state.refs ~p~n",[State#state.refs]),  
    NewTerm={NewNode,NewPid,NewRef,App},
    
    NewState=State#state{refs=[NewTerm|Refs]},
    io:format("State ~p~n",[State]),
    io:format("NewState ~p~n",[NewState]),
    io:format("nodes() ~p~n",[nodes()]),
    {noreply, NewState};

handle_info(Info,State) ->
    io:format("unmatched match info ~p~n",[{?MODULE,?LINE,Info}]),
    {noreply, State}.


%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
lrpc(Pid,F,A,T)->
    io:format("Pid,F,A,T ~p~n",[{Pid,F,A,T,?MODULE,?LINE}]),
    Pid!{self(),F,A},
    Result=receive
	       {Pid,R}->
		   R
	   after T->
		   {error,[timeout]}
	   end,
    Result.
