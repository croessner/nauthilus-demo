-- backend.lua demo

function nauthilus_backend_verify_password(request)
    local backend_result = nauthilus_backend_result.new()
    local attributes = {}

    if request.username == "testuser" then
        backend_result:user_found(true)
        backend_result:account_field("account")

        attributes.account = "testaccount"

        if not request.no_auth then
            if request.password == "testpassword" then
                backend_result:authenticated(true)
            end
        end
    end

    backend_result:attributes(attributes)

    return nauthilus_builtin.BACKEND_RESULT_OK, backend_result
end

function nauthilus_backend_list_accounts()
    return nauthilus_builtin.BACKEND_RESULT_OK, { "testuser" }
end
