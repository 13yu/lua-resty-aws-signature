Name
====

lua-resty-aws-signature - Lua library for signing or authenticating a request use aws signature version 4


Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsis](#synopsis)
* [Description](#description)
* [Installation](#installation)
* [Author](#author)
* [Copyright and License](#copyright-and-license)

Status
======

This library is already usable though still highly experimental.

The Lua API is still in flux and may change in the near future without notice.

Synopsis
========

[Back to TOC](#table-of-contents)

```nginx
# demonstrate the usage of the resty.aws_signature.aws_signer module
http {
    server {
        location / {
            rewrite_by_lua_block {
                local aws_signer = require "resty.aws_signature.aws_signer"

                local access_key = 'ziw5dp1alvty9n47qksu'
                local secret_key = 'V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV'

                local signer = aws_signer.new(access_key, secret_key)

                local request = {
                    verb = 'PUT',
                    uri = 'foo/bar%3Fbar',
                    args = {
                        foo1 = 'bar1',
                        foo3 = true,
                        foo2 = 'bar2',
                    },
                    headers = {
                        Host = '127.0.0.1',
                        ['Content-Length'] = '7',
                    },
                    body = 'bla bla'
                }

                local ctx, err, msg = signer:add_auth_v4(request, {sign_payload = true})
                if err ~= nil then
                    ngx.log(ngx.ERR, err .. ' ' .. msg)
                end

                -- This method will modify the request passed in, add signatrue to query string
                -- or to the 'Authorization' header. It also add the args to the uri.
                -- After call this method, you can send the request, using the modified uri and headers
            }
        }
    }
}
```

```nginx
# demonstrate the usage of the resty.aws_signature.aws_authenticator module
http {
    lua_shared_dict signing_key 10m;

    server {
        location / {
            rewrite_by_lua_block {
                local aws_authenticator = require "resty.aws_signature.aws_authenticator"

                local access_key = 'ziw5dp1alvty9n47qksu'
                local secret_key = 'V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV'

                local function get_secret_key(access_key_in_request)
                     -- You should return the secret key corresponding to the access_key_in_request
                     -- passed in, you may need to query your database.
                     if access_key_in_request == access_key then
                         return secret_key
                     end
                     return nil, 'InvalidAccessKey', 'the access key does not exists: ' ..
                              access_key_in_request
                end

                local function get_bucket_from_host(host)
                    -- you should return the bucket name in the host header, it is only used for
                    -- authenticating signature of version 2, for simplicity, we just return nil here
                    return nil
                end

                authenticator = aws_authenticator.new(get_secret_key,
                                                      get_bucket_from_host,
                                                      ngx.shared.signing_key)

                ctx, err, msg = authenticator:authenticate()
                if err != nil then
                    ngx.log(ngx.ERR, 'authenticate failed: ' .. err .. ' ' .. msg)
                end
            }
        }
    }
}
```

[Back to TOC](#table-of-contents)

Description
===========

This library provides two Lua modules, one for adding signature and one for authenticating.
When adding signautrue, we only support aws signatrue version 4, you can not use this module
to add signature of version 2. While the authenticating module support both signature version 4
and version 2

* [resty.aws_signature.aws_signer](lib/resty/aws_signature/aws_signer.md) add signature to a request use aws signature version 4.
* [resty.aws_signature.aws_authenticator](lib/resty/aws_signature/aws_authenticator.md) to authenticate the signature in a request.

Please check out these Lua modules' own documentation for more details.

[Back to TOC](#table-of-contents)

Installation
============

Copy the resty directory to a location which is in the seaching path of lua require module

[Back to TOC](#table-of-contents)

Author
======

Renzhi (任稚) <zhi.ren@baishancloud.com>.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2015-2017, by Yichun "agentzh" Zhang, OpenResty Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)
