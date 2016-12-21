# vi:ft=

use Test::Nginx::Socket::Lua;

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

our $HttpConfig = <<'_EOC_';
    #lua_code_cache off;
    lua_package_path 'lib/?.lua;;';
    lua_package_cpath 'lib/?.so;;';
_EOC_

no_long_string();

run_tests();

__DATA__

=== TEST 1: basic test
--- http_config eval: $::HttpConfig
--- config
    location /t {
        rewrite_by_lua '
            local aws_signer = require("resty.aws_signature.aws_signer")
            local aws_authenticator = require("resty.aws_signature.aws_authenticator")

            local access_key = "ziw5dp1alvty9n47qksu"
            local secret_key = "V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV"
            local signer, err, msg = aws_signer.new(access_key, secret_key)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to new a aws_signer" .. err .. " " .. msg)
            end

            local request = {
                verb = "GET",
                uri = "/",
                headers = {
                    Host = "127.0.0.1",
                },
            }

            local ctx, err, msg = signer:add_auth_v4(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to add auth: " .. err .. " " .. msg)
            end

            ngx.say(request.uri)
            ngx.say(request.headers.Authorization)
            ngx.say(request.headers["X-Amz-Content-SHA256"])
            ngx.say(request.headers["X-Amz-Date"])

            local function get_secret_key(secret_key_in_request)
                return secret_key
            end
            local function get_bucket_from_host(host)
                return nil
            end
            local authenticator = aws_authenticator.new(get_secret_key, get_bucket_from_host)

            local low_headers = {}
            for k, v in pairs(request.headers) do
                low_headers[k:lower()] = v
            end
            request.headers = low_headers
            local ctx, err, msg = authenticator:authenticate(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "authenticate failed: " .. err .. " " .. msg)
            end
            ngx.say(ctx.access_key)
        ';
    }
--- request
GET /t
--- response_body_like
/
AWS4-HMAC-SHA256 Credential=ziw5dp1alvty9n47qksu/[0-9]{8}/us-east-1/s3/aws4_request, SignedHeaders=host;x-amz-date, Signature=[0-9a-f]{64}
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
[0-9]{8}T[0-9]{6}Z
ziw5dp1alvty9n47qksu
--- no_error_log
[error]


=== TEST 2: test has query string in uri
--- http_config eval: $::HttpConfig
--- config
    location /t {
        rewrite_by_lua '
            local aws_signer = require("resty.aws_signature.aws_signer")
            local aws_authenticator = require("resty.aws_signature.aws_authenticator")

            local access_key = "ziw5dp1alvty9n47qksu"
            local secret_key = "V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV"
            local signer, err, msg = aws_signer.new(access_key, secret_key)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to new a aws_signer" .. err .. " " .. msg)
            end

            local request = {
                verb = "GET",
                uri = "/aaa/bbb?foo=bar",
                headers = {
                    Host = "127.0.0.1",
                },
            }

            local auth_ctx, err, msg = signer:add_auth_v4(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to add auth: " .. err .. " " .. msg)
            end

            ngx.say(request.uri)
            ngx.say(request.headers.Authorization)

            local function get_secret_key(secret_key_in_request)
                return secret_key
            end
            local function get_bucket_from_host(host)
                return nil
            end
            local authenticator = aws_authenticator.new(get_secret_key, get_bucket_from_host)

            request.uri = "/aaa/bbb"
            request.args = {
                foo = "bar",
            }
            local low_headers = {}
            for k, v in pairs(request.headers) do
                low_headers[k:lower()] = v
            end
            request.headers = low_headers
            local ctx, err, msg = authenticator:authenticate(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "authenticate failed: " .. err .. " " .. msg)
            end
            ngx.say(ctx.access_key)
        ';
    }
--- request
GET /t
--- response_body_like
/aaa/bbb\?foo=bar
AWS4-HMAC-SHA256 Credential=ziw5dp1alvty9n47qksu/[0-9]{8}/us-east-1/s3/aws4_request, SignedHeaders=host;x-amz-date, Signature=[0-9a-f]{64}
ziw5dp1alvty9n47qksu
--- no_error_log
[error]


=== TEST 3: do not contain query string in uri, and specify args in request
--- http_config eval: $::HttpConfig
--- config
    location /t {
        rewrite_by_lua '
            local aws_signer = require("resty.aws_signature.aws_signer")
            local aws_authenticator = require("resty.aws_signature.aws_authenticator")

            local access_key = "ziw5dp1alvty9n47qksu"
            local secret_key = "V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV"
            local signer, err, msg = aws_signer.new(access_key, secret_key)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to new a aws_signer" .. err .. " " .. msg)
            end

            local request = {
                verb = "GET",
                uri = "/",
                args = {
                    foo2 = "bar2",
                    foo1 = "bar1",
                    foo3 = true,
                },
                headers = {
                    Host = "127.0.0.1",
                },
            }

            local auth_ctx, err, msg = signer:add_auth_v4(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to add auth: " .. err .. " " .. msg)
            end

            ngx.say(request.uri)
            ngx.say(request.headers.Authorization)

            local function get_secret_key(secret_key_in_request)
                return secret_key
            end
            local function get_bucket_from_host(host)
                return nil
            end
            local authenticator = aws_authenticator.new(get_secret_key, get_bucket_from_host)

            request.uri = "/"
            local low_headers = {}
            for k, v in pairs(request.headers) do
                low_headers[k:lower()] = v
            end
            request.headers = low_headers
            local ctx, err, msg = authenticator:authenticate(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "authenticate failed: " .. err .. " " .. msg)
            end
            ngx.say(ctx.access_key)
        ';
    }
--- request
GET /t
--- response_body_like
/\?foo3&foo1=bar1&foo2=bar2
AWS4-HMAC-SHA256 Credential=ziw5dp1alvty9n47qksu/[0-9]{8}/us-east-1/s3/aws4_request, SignedHeaders=host;x-amz-date, Signature=[0-9a-f]{64}
ziw5dp1alvty9n47qksu
--- no_error_log
[error]


=== TEST 4: test have payload but not sign payload
--- http_config eval: $::HttpConfig
--- config
    location /t {
        rewrite_by_lua '
            local aws_signer = require("resty.aws_signature.aws_signer")
            local aws_authenticator = require("resty.aws_signature.aws_authenticator")

            local access_key = "ziw5dp1alvty9n47qksu"
            local secret_key = "V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV"
            local signer, err, msg = aws_signer.new(access_key, secret_key)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to new a aws_signer" .. err .. " " .. msg)
            end

            local request = {
                verb = "PUT",
                uri = "/",
                headers = {
                    Host = "127.0.0.1",
                },
                body = "bla bla",
            }

            local auth_ctx, err, msg = signer:add_auth_v4(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to add auth: " .. err .. " " .. msg)
            end

            ngx.say(request.uri)
            ngx.say(request.headers.Authorization)
            ngx.say(request.headers["X-Amz-Content-SHA256"])

            local function get_secret_key(secret_key_in_request)
                return secret_key
            end
            local function get_bucket_from_host(host)
                return nil
            end
            local authenticator = aws_authenticator.new(get_secret_key, get_bucket_from_host)

            local low_headers = {}
            for k, v in pairs(request.headers) do
                low_headers[k:lower()] = v
            end
            request.headers = low_headers
            local ctx, err, msg = authenticator:authenticate(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "authenticate failed: " .. err .. " " .. msg)
            end
            ngx.say(ctx.access_key)
        ';
    }
--- request
GET /t
--- response_body_like
/
AWS4-HMAC-SHA256 Credential=ziw5dp1alvty9n47qksu/[0-9]{8}/us-east-1/s3/aws4_request, SignedHeaders=host;x-amz-date, Signature=[0-9a-f]{64}
fdcf4254fc02e5e41e545599f0be4f9f65e8be431ebc1fd301a96ea88dd0d5d6
ziw5dp1alvty9n47qksu
--- no_error_log
[error]


=== TEST 5: test have payload and sign the payload
--- http_config eval: $::HttpConfig
--- config
    location /t {
        rewrite_by_lua '
            local aws_signer = require("resty.aws_signature.aws_signer")
            local aws_authenticator = require("resty.aws_signature.aws_authenticator")

            local access_key = "ziw5dp1alvty9n47qksu"
            local secret_key = "V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV"
            local signer, err, msg = aws_signer.new(access_key, secret_key)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to new a aws_signer" .. err .. " " .. msg)
            end

            local request = {
                verb = "PUT",
                uri = "/",
                headers = {
                    Host = "127.0.0.1",
                },
                body = "bla bla"
            }

            local auth_ctx, err, msg = signer:add_auth_v4(request, {sign_payload = true})
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to add auth: " .. err .. " " .. msg)
            end

            ngx.say(request.uri)
            ngx.say(request.headers.Authorization)
            ngx.say(request.headers["X-Amz-Content-SHA256"])

            local function get_secret_key(secret_key_in_request)
                return secret_key
            end
            local function get_bucket_from_host(host)
                return nil
            end
            local authenticator = aws_authenticator.new(get_secret_key, get_bucket_from_host)

            local low_headers = {}
            for k, v in pairs(request.headers) do
                low_headers[k:lower()] = v
            end
            request.headers = low_headers
            local ctx, err, msg = authenticator:authenticate(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "authenticate failed: " .. err .. " " .. msg)
            end
            ngx.say(ctx.access_key)
        ';
    }
--- request
GET /t
--- response_body_like
/
AWS4-HMAC-SHA256 Credential=ziw5dp1alvty9n47qksu/[0-9]{8}/us-east-1/s3/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=[0-9a-f]{64}
fdcf4254fc02e5e41e545599f0be4f9f65e8be431ebc1fd301a96ea88dd0d5d6
ziw5dp1alvty9n47qksu
--- no_error_log
[error]


=== TEST 6: test specify X-Amz-Content-SHA256 in headers
--- http_config eval: $::HttpConfig
--- config
    location /t {
        rewrite_by_lua '
            local aws_signer = require("resty.aws_signature.aws_signer")
            local aws_authenticator = require("resty.aws_signature.aws_authenticator")

            local access_key = "ziw5dp1alvty9n47qksu"
            local secret_key = "V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV"
            local signer, err, msg = aws_signer.new(access_key, secret_key)
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to new a aws_signer" .. err .. " " .. msg)
            end

            local request = {
                verb = "PUT",
                uri = "/",
                headers = {
                    Host = "127.0.0.1",
                    ["X-Amz-Content-SHA256"] = "1234567890123456789012345678901234567890123456789012345678901234",
                },
                body = "bla bla"
            }

            local auth_ctx, err, msg = signer:add_auth_v4(request, {sign_payload = true})
            if err ~= nil then
                ngx.log(ngx.ERR, "failed to add auth: " .. err .. " " .. msg)
            end

            ngx.say(request.uri)
            ngx.say(request.headers.Authorization)
            ngx.say(request.headers["X-Amz-Content-SHA256"])

            local function get_secret_key(secret_key_in_request)
                return secret_key
            end
            local function get_bucket_from_host(host)
                return nil
            end
            local authenticator = aws_authenticator.new(get_secret_key, get_bucket_from_host)

            local low_headers = {}
            for k, v in pairs(request.headers) do
                low_headers[k:lower()] = v
            end
            request.headers = low_headers
            local ctx, err, msg = authenticator:authenticate(request)
            if err ~= nil then
                ngx.log(ngx.ERR, "authenticate failed: " .. err .. " " .. msg)
            end
            ngx.say(ctx.access_key)
        ';
    }
--- request
GET /t
--- response_body_like
/
AWS4-HMAC-SHA256 Credential=ziw5dp1alvty9n47qksu/[0-9]{8}/us-east-1/s3/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=[0-9a-f]{64}
1234567890123456789012345678901234567890123456789012345678901234
ziw5dp1alvty9n47qksu
--- no_error_log
[error]
