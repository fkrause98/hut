%% -*- erlang -*-

-ifndef(__HUT_HRL__).
-define(__HUT_HRL__, true).

%% Supported logging levels (taken from lager):
-define(__log_levels, [debug, info, notice, warning, error, critical, alert, emergency]).
-define(__default_log_level, info).
-define(__default_use_log_level_gate, true).

%% Helper macros
-define(__fmt(__Fmt, __Args), lists:flatten(io_lib:format(__Fmt, __Args))).

-define(__maybe_log(__Level, __Fun),
        ((fun() ->
                   __UseGate = application:get_env(hut, use_log_level_gate, ?__default_use_log_level_gate),
                  case __UseGate of
                      true ->
                          __CurrentLevel = application:get_env(hut, level, ?__default_log_level),
                          __AllowedLevels = lists:dropwhile(fun(__Element) -> __Element =/= __CurrentLevel end, ?__log_levels),
                          __IsEnabled = lists:member(__Level, __AllowedLevels),
                          case __IsEnabled of
                              true ->
                                  __Fun();
                              _ ->
                                  ok
                          end;
                      _ ->
                          __Fun()
                  end
          end)())).

%% Lager support

-ifdef(HUT_LAGER).
-define(log_type, "lager").

-ifndef(HUT_LAGER_SINK).
-define(HUT_LAGER_SINK, lager).
-endif.

-define(log(__Level, __Fmt),
        ?HUT_LAGER_SINK:__Level([], __Fmt, [])).
-define(log(__Level, __Fmt, __Args),
        ?HUT_LAGER_SINK:__Level([], __Fmt, __Args)).
-define(log(__Level, __Fmt, __Args, __Opts),
        ?HUT_LAGER_SINK:__Level(__Opts, __Fmt, __Args)).

-else.

% Using plain `io:format/2`.

-ifdef(HUT_IOFORMAT).
-define(log_type, "ioformat").

-define(log(__Level, __Fmt),
        ?__maybe_log(__Level, fun() -> io:format("~p: " ++ __Fmt ++ "~n", [__Level]) end)).
-define(log(__Level, __Fmt, __Args),
        ?__maybe_log(__Level, fun() -> io:format("~p: " ++ __Fmt ++ "~n", [__Level] ++ __Args) end)).
-define(log(__Level, __Fmt, __Args, __Opts),
        ?__maybe_log(__Level, fun() -> io:format("~p: " ++ __Fmt ++ "; Opts: ~p~n", [__Level] ++ __Args ++ [__Opts]) end)).

-else.

% All logging calls are passed into a custom logging callback module given by `HUT_CUSTOM_CB`.

-ifdef(HUT_CUSTOM).
-ifdef(HUT_CUSTOM_CB).
-define(log_type, "custom").

-define(log(__Level, __Fmt),
        ?__maybe_log(__Level, fun() -> ?HUT_CUSTOM_CB:log(__Level, __Fmt, [], []) end)).
-define(log(__Level, __Fmt, __Args),
        ?__maybe_log(__Level, fun() -> ?HUT_CUSTOM_CB:log(__Level, __Fmt, __Args, []) end)).
-define(log(__Level, __Fmt, __Args, __Opts),
        ?__maybe_log(__Level, fun() -> ?HUT_CUSTOM_CB:log(__Level, __Fmt, __Args, __Opts) end)).

-endif.
-else.

% All logging calls are ignored.

-ifdef(HUT_NOOP).
-define(log_type, "noop").

-define(log(__Level, __Fmt), true).
-define(log(__Level, __Fmt, __Args), true).
-define(log(__Level, __Fmt, __Args, __Opts), true).

-else.

-ifndef(OTP_RELEASE).
% If none of the above options were defined and OTP version is below 21, default to SASL
-define(HUT_SASL, true).
-endif.

-ifdef(HUT_SASL).

-define(log_type, "sasl").

-define(log(__Level, __Fmt),
        ?__maybe_log(__Level, fun() -> hut:log(?log_type, __Level, __Fmt, [], []) end)).
-define(log(__Level, __Fmt, __Args),
        ?__maybe_log(__Level, fun() -> hut:log(?log_type, __Level, __Fmt, __Args, []) end)).
-define(log(__Level, __Fmt, __Args, __Opts),
        ?__maybe_log(__Level, fun() -> hut:log(?log_type, __Level, __Fmt, __Args, __Opts) end)).

-else.

% On OTP21+ use logger by default

-define(log_type, "logger").

-define(__hut_logger_metadata,
        #{ mfa => {?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY}
         , file => ?FILE
         , line => ?LINE
         }).

-define(log(__Level, __Fmt, __Args, __Opts),
        logger:log(__Level, __Fmt ++ "; Opts ~p", __Args ++ [__Opts], ?__hut_logger_metadata)).
-define(log(__Level, __Fmt, __Args),
        logger:log(__Level, __Fmt, __Args, ?__hut_logger_metadata)).
-define(log(__Level, __Fmt),
        ?log(__Level, __Fmt, [])).

% Structured report:
-define(slog(__Level, __Data, __Meta),
        logger:log(__Level, __Data, maps:merge(?__hut_logger_metadata, __Meta))).
-define(slog(__Level, __Data),
        ?slog(__Level, __Data, #{})).

% End of all actual log implementation switches.
-endif.
-endif.
-endif.
-endif.
-endif.

-ifndef(slog).
-define(slog(__Level, __Data),
        ?log(__Level, "~p", [__Data])).

-define(slog(__Level, __Data, __Meta),
        ?log(__Level, "~p; ~p", [__Data, __Meta])).

-endif.

% End of log declarations
-endif.
