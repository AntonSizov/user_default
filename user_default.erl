-module(user_default).

-export([help/0]).

-export([dbg/0]).
-export([dbg/1]).
-export([dbg/2]).
-export([dbg/3]).
-export([dbg/4]).

-export([etv/0]).
-export([etv/1]).

-export([status/1]).
-export([kill/1, kill/2]).
-export([os/1]).

-compile(inline).

help() ->
    Exports = lists:keysort(1, ?MODULE:module_info(exports)),
    shell_default:help(),
    io:format("** commands in module user_default **\n"),
    [ begin
	  Args = "(" ++ string:join(lists:duplicate(Arity, "_"), ",") ++ ")",
	  Cmd = atom_to_list(Fun) ++ Args,
	  Spaces = lists:duplicate(15 - length(Cmd), 32),
	  io:format("~s~s -- unknown~n", [Cmd, Spaces])
      end || {Fun, Arity} <- Exports, Fun =/= help, Fun =/= module_info ],
    true.

%% ===================================================================
%% DBG
%% ===================================================================

dbg()										-> dbg:tracer().

dbg(c)										-> dbg:stop_clear();
dbg(M)										-> dbgg({M, '_', '_'}, []).

dbg(M, c)									-> dbgc({M, '_', '_'});
dbg(M, r)									-> dbgg({M, '_', '_'}, dbg_rt());
dbg(M, l)									-> dbgl({M, '_', '_'}, []);
dbg(M, lr)									-> dbgl({M, '_', '_'}, dbg_rt());
dbg(M, rl)									-> dbgl({M, '_', '_'}, dbg_rt());
dbg(M, F) when is_atom(F)					-> dbgg({M,   F, '_'}, []);
dbg(M, Fn2Ms) when is_function(Fn2Ms)		-> dbgf({M, '_', '_'}, Fn2Ms);
dbg(M, O)									-> dbgg({M, '_', '_'}, O).

dbg(M, F, c)								-> dbgc({M,   F, '_'});
dbg(M, F, l)								-> dbgl({M,   F, '_'}, dbg_rt());
dbg(M, F, r)								-> dbgg({M,   F, '_'}, dbg_rt());
dbg(M, F, lr)								-> dbgl({M,   F, '_'}, dbg_rt());
dbg(M, F, rl)								-> dbgl({M,   F, '_'}, dbg_rt());
dbg(M, F, A) when is_integer(A)				-> dbgg({M,   F,   A}, []);
dbg(M, F, Fn2Ms) when is_function(Fn2Ms)	-> dbgf({M,   F, '_'}, Fn2Ms);
dbg(M, F, O)								-> dbgg({M,   F, '_'}, O).

dbg(M, F, A, c)								-> dbgc({M,   F,   A});
dbg(M, F, A, r)								-> dbgg({M,   F,   A}, dbg_rt());
dbg(M, F, A, l)								-> dbgl({M,   F,   A}, dbg_rt());
dbg(M, F, A, lr)							-> dbgl({M,   F,   A}, dbg_rt());
dbg(M, F, A, rl)							-> dbgl({M,   F,   A}, dbg_rt());
dbg(M, F, A, Fn2Ms) when is_function(Fn2Ms) -> dbgf({M,   F,   A}, Fn2Ms);
dbg(M, F, A, O)								-> dbgg({M,   F,   A}, O).

%% ===================================================================
%% DBG Internal
%% ===================================================================

dbgc(MFA)    -> dbg:ctp(MFA).
dbgg(MFA, O) -> dbg:tracer(), dbg:p(all, call), dbg:tp(MFA, O).
dbgl(MFA, O) -> dbg:tracer(), dbg:p(all, call), dbg:tpl(MFA, O).
dbgf(MFA, F) -> dbg:tracer(), dbg:p(all, call), dbg:tpl(MFA, dbg:fun2ms(F)).
dbg_rt() -> [{'_', [], [{return_trace}, {exception_trace}]}].

%% ===================================================================
%% Event Viewer
%% ===================================================================

etv() ->
	etv("").

etv(Title) ->
	et_viewer:start([
		{title, Title},
		{trace_global, true},
		{trace_pattern, {et, max}}
	]).

%% ===================================================================
%% Pid generic
%% ===================================================================

-type reg_name() :: atom().
-spec pid_do(pid() | reg_name(), fun((pid()) -> any())) -> any().
pid_do(Pid, Fun) when is_pid(Pid) ->
	Fun(Pid);
pid_do(RegName, Fun) when is_atom(RegName), RegName =/= undefined ->
	Pid = whereis(RegName),
	pid_do(Pid, Fun);
pid_do(_, _) ->
	io:format("Invalid process~n").

%% ===================================================================
%% Process status
%% ===================================================================

-spec status(pid() | reg_name()) -> any().
status(PidOrRegName) ->
	pid_do(PidOrRegName, fun sys:get_status/1).

%% ===================================================================
%% Kill process
%% ===================================================================

-type reason() :: term().
-spec kill(pid() | reg_name(), reason()) -> any().
kill(PidOrRegName, Reason) ->
	pid_do(PidOrRegName, fun(Pid) -> erlang:exit(Pid, Reason) end).

-spec kill(pid() | reg_name()) -> any().
kill(PidOrRegName) ->
	kill(PidOrRegName, kill).

%% ===================================================================
%% OS command
%% ===================================================================

os(Command) ->
	Res = os:cmd(Command),
	io:format("~s~n", [Res]).