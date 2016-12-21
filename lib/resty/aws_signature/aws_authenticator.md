Name
====

resty.aws_signature.aws_authenticator - Lua module for authenticating signature in a request.

Table of Contents
=================

* [Name](#name)
* [Synopsis](#synopsis)
* [Description](#description)
* [Methods](#methods)
    * [new](#new)
    * [authenticate](#authenticate)
* [Author](#author)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Synopsis
========

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
                     -- you should return the secret key corresponding to the access_key_in_request passed in
                     -- you may need to query your database.
                     if access_key_in_request == access_key then
                         return secret_key
                     end
                     return nil, 'InvalidAccessKey', 'the access key does not exists: ' .. access_key_in_request
                end

                local function get_bucket_from_host(host)
                    -- you should return the bucket name in the host header, it is only used for authenticating
                    -- signature of version 2, for simplicity, we just return nil here
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

This module provides API to help the OpenResty/ngx_lua user porgrammers to authenticate a request, which
have signature of version 4 or version 2.

Methods
=======

[Back to TOC](#table-of-contents)

new
---
**syntax:** `obj, err, msg = class.new(get_secret_key, get_bucket_from_host, shared_dict)`

Instantiates an object of this class. The `class` value is returned by the call `require "resty.aws_signature.aws_authenticator"`.

This method takes the following arguments:

* `get_secret_key` is a callback function you need to impliment.

    the only parameter to this function is the access key found in the request, and the return value should be the corresponding
    secret key.

* `get_bucket_from_host` is a callback function you need to impliment.
    the only parameter to this function is the host header value, and the return value should be the bucket name in the host,
    this function is only used when authenticating signatrue of version 2.

* `shared_dict` is the name of the lua_shared_dict shm zone, which will be used to cache the signing key, it can be omited, if you
    do not want to cache the signing key.

[Back to TOC](#table-of-contents)

add_auth_v4
--------
**syntax:** `ctx, err, msg = obj:authenticate(ctx)`

[Back to TOC](#table-of-contents)

authenticate the signature in the request.

This method takes the following arguments:

* `ctx` is a lua table which contain all information about the request.
    It can be omited. It may contain the following keys:

 - `verb` the request method, such as 'PUT', 'GET'.

 - `uri` the request uri, do not contain the query string.

 - `args` the request args in query string.

 - `headers` the request headers.

The return values depend on the following cases:

1. If authentication succeed, the method will return a lua table which contains come intermidiate values used in the
authenticating process, it is usefull for debuging.

2. If something go wrong, this method will return an error code and an error message.

Author
======

Renzhi (任稚) <zhi.ren@baishancloud.com>.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2015-2016, by Yichun "agentzh" Zhang, CloudFlare Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)
