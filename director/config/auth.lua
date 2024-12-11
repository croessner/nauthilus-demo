--
-- START settings
--

local http_debug = false;
local http_uri = "http://nauthilus:8080/api/v1/auth/header"
local http_access_denied = "Account not enabled"

--
-- END settings
--

local PASSDB = "passdb"
local USERDB = "userdb"

-- HTTP defaults
local http_client = dovecot.http.client{
    timeout = 300;
    max_attempts = 3;
    debug = http_debug;
    user_agent = "Dovecot/2.3";
}

local function query_db(request, password, dbtype)
    local remote_ip = request.remote_ip
    local remote_port = request.remote_port
    local local_ip = request.local_ip
    local local_port = request.local_port
    local client_id = request.client_id
    local qs_noauth = ""
    local extra_fields = {}

    local function add_extra_field(pf, key, value)
        if value ~= nil and value:len()>0 then
            extra_fields[pf .. key] = value
        end
    end

    if dbtype == USERDB then
        qs_noauth = "?mode=no-auth"
    end
    local auth_request = http_client:request {
        url = http_uri .. qs_noauth;
        method = "POST";
    }

    if remote_ip == nil then
        remote_ip = "0.0.0.0"
    end
    if remote_port == nil then
        remote_port = "0"
    end
    if local_ip == nil then
        local_ip = "0.0.0.0"
    end
    if local_port == nil then
        local_port = "0"
    end
    if client_id == nil then
        client_id = ""
    end

    auth_request:add_header("X-Nauthilus-Service", "Dovecot")
    auth_request:add_header("X-Nauthilus-Username", request.user)
    auth_request:add_header("X-Nauthilus-Password", password)
    auth_request:add_header("X-Nauthilus-Client-IP", remote_ip)
    auth_request:add_header("X-Nauthilus-Client-Port", remote_port)
    auth_request:add_header("X-Nauthilus-Local-IP", local_ip)
    auth_request:add_header("X-Nauthilus-Local-Port", local_port)
    auth_request:add_header("X-Nauthilus-Protocol", request.service)

    if request.secured == "TLS" or request.secured == "secured" then
        auth_request:add_header("X-Nauthilus-SSL", "1")
    end

    if request.session ~= nil then
        auth_request:add_header("X-Dovecot-Session", request.session)
    end

    -- Send
    local auth_response = auth_request:submit()

    -- Response
    local auth_status_code = auth_response:status()
    local auth_status_message = auth_response:header("Auth-Status")
    local dovecot_account = auth_response:header("Auth-User")
    local nauthilus_session = auth_response:header("X-Nauthilus-Session")
    local proxy_host = auth_response:header("X-Nauthilus-Proxy-Host")

    dovecot.i_info("request=" .. dbtype .. " service=" .. request.service .. " proxy_host=" .. proxy_host .. " auth_status_code=" .. tostring(auth_status_code) .. " auth_status_message=<" .. auth_status_message .. "> nauthilus_session=" .. nauthilus_session)

    -- Handle valid logins
    if auth_status_code == 200 then
        local pf = ""

        if dovecot_account and dovecot_account ~= "" then
            add_extra_field("", "user", dovecot_account)
        end

        if dbtype == PASSDB then
            pf = "userdb_"
        end

        extra_fields.proxy = "y"
        extra_fields.proxy_timeout = "120"
        extra_fields.host = proxy_host

        if dbtype == PASSDB then
            return dovecot.auth.PASSDB_RESULT_OK, extra_fields
        else
            return dovecot.auth.USERDB_RESULT_OK, extra_fields
        end
    end

    -- Handle failed logins
    if auth_status_code == 403 then
        if dbtype == PASSDB then
            if auth_status_message == http_access_denied then
                return dovecot.auth.PASSDB_RESULT_USER_DISABLED, auth_status_message
            end

            return dovecot.auth.PASSDB_RESULT_PASSWORD_MISMATCH, auth_status_message
        else
            return dovecot.auth.USERDB_RESULT_USER_UNKNOWN, auth_status_message
        end
    end

    -- Unable to communicate with Nauthilus (implies status codes 50X)
    if dbtype == PASSDB then
        return dovecot.auth.PASSDB_RESULT_INTERNAL_FAILURE, ""
    else
        return dovecot.auth.USERDB_RESULT_INTERNAL_FAILURE, ""
    end
end

function auth_userdb_lookup(request)
    return query_db(request, "", USERDB)
end

function auth_password_verify(request, password)
    return query_db(request, password, PASSDB)
end

function auth_passdb_lookup(request)
    local result, extra_fields = query_db(request, "", USERDB)

    if type(extra_fields) == "table" then
        extra_fields.nopassword = "y"
    else
        extra_fields = { nopassword = "y" }
    end

    return result, extra_fields
end

function script_init()
    return 0
end

function script_deinit()
end

function auth_userdb_iterate()
    return { "testaccount" }
end
