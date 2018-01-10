%%%----------------------------------------------------------------------
%%% File    : mod_muc_light_codec.erl
%%% Author  : Piotr Nosek <piotr.nosek@erlang-solutions.com>
%%% Purpose : MUC Light codec behaviour
%%% Created : 29 Sep 2015 by Piotr Nosek <piotr.nosek@erlang-solutions.com>
%%%----------------------------------------------------------------------

-module(mod_muc_light_codec).
-author('piotr.nosek@erlang-solutions.com').

-include("mod_muc_light.hrl").
-include("jlib.hrl").

%% API
-export([encode_error/6]).

-type encoded_packet_handler() ::
    fun((From :: ejabberd:jid(), To :: ejabberd:jid(), Packet :: jlib:xmlel()) -> any()).

-type decode_result() :: {ok, muc_light_packet() | muc_light_disco() | ejabberd:iq()}
                       | {error, bad_request} | ignore.

-export_type([encoded_packet_handler/0, decode_result/0]).

%%====================================================================
%% Behaviour callbacks
%%====================================================================

-callback decode(From :: ejabberd:jid(), To :: ejabberd:jid(), Stanza :: jlib:xmlel()) ->
    decode_result().

-callback encode(Request :: muc_light_encode_request(), OriginalSender :: ejabberd:jid(),
                 RoomUS :: ejabberd:simple_bare_jid(), % may be just service domain
                 HandleFun :: encoded_packet_handler()) -> any().

-callback encode_error(ErrMsg :: tuple(), OrigFrom :: ejabberd:jid(), OrigTo :: ejabberd:jid(),
                       OrigPacket :: jlib:xmlel(), HandleFun :: encoded_packet_handler()) ->
    any().

%%====================================================================
%% API
%%====================================================================

-spec encode_error(ErrMsg :: tuple(), ExtraChildren :: [jlib:xmlch()], OrigFrom :: ejabberd:jid(),
                   OrigTo :: ejabberd:jid(), OrigPacket :: jlib:xmlel(),
                   HandleFun :: encoded_packet_handler()) -> any().
encode_error(ErrMsg, ExtraChildren, OrigFrom, OrigTo, OrigPacket, HandleFun) ->
    ErrorElem = make_error_elem(ErrMsg),
    ErrorPacket = jlib:make_error_reply(OrigPacket#xmlel{ children = ExtraChildren }, ErrorElem),
    HandleFun(OrigTo, OrigFrom, ErrorPacket).

-spec make_error_elem(tuple()) -> jlib:xmlel().
make_error_elem({error, not_allowed}) ->
    mongoose_xmpp_errors:not_allowed();
make_error_elem({error, bad_request}) ->
    mongoose_xmpp_errors:bad_request();
make_error_elem({error, item_not_found}) ->
    mongoose_xmpp_errors:item_not_found();
make_error_elem({error, conflict}) ->
    mongoose_xmpp_errors:conflict();
make_error_elem({error, bad_request, Text}) ->
    ?ERRT_BAD_REQUEST(<<"en">>, iolist_to_binary(Text));
make_error_elem({error, feature_not_implemented}) ->
    mongoose_xmpp_errors:feature_not_implemented();
make_error_elem({error, internal_server_error}) ->
    mongoose_xmpp_errors:internal_server_error();
make_error_elem({error, registration_required}) ->
    mongoose_xmpp_errors:registration_required();
make_error_elem({error, _}) ->
    mongoose_xmpp_errors:bad_request().

