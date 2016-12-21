Name
====

resty.aws_signature.aws_signer - Lua module for adding signature to a request.

Table of Contents
=================

* [Name](#name)
* [Synopsis](#synopsis)
* [Description](#description)
* [Methods](#methods)
    * [new](#new)
    * [add_auth_v4](#add_auth_v4)
* [Author](#author)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Synopsis
========

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
                    ngx.log(ngx.ERR, "failed to sign: " .. err .. " " .. msg)
                end
            }
        }
    }
}
```

[Back to TOC](#table-of-contents)

Description
===========

This module provides API to help the OpenResty/ngx_lua user porgrammers to generate a signed request,
you need to provide a lua table which present your request(typically it contains the request verb, uri,
args, headers, body) and your access key and your secret key, this module will add signature and some
related info to query string or to the Authorization header. this module will modify uri and headers
you passed in, and you should send the request use the modified uri and headers.

Methods
=======

[Back to TOC](#table-of-contents)

new
---
**syntax:** `obj, err, msg = class.new(access_key, secret_key, opts)`

Instantiates an object of this class. The `class` value is returned by the call `require "resty.aws_signature.aws_signer"`.

This method takes the following arguments:

* `access_key` is the access key.

* `secret_key` is the secret key.

* `opts` is the optional arguments, can be omited. You can specify the following options:

 - `region` to spedify the region you will request to, the default is 'us-east-1'.

 - `service` is the service name, the default is 's3'.

 - `default_expires` the default expire time of a presigned url in seconds, the default is 60.

 - `shared_dict` is the name of the lua_shared_dict shm zone, which will be used to cache the signing key, the default is nil.

[Back to TOC](#table-of-contents)

add_auth_v4
--------
**syntax:** `ctx, err, msg = obj:add_auth_v4(request, opts)`

calculate the signature and add it to the request, this method will modify the request you passed in.

This method accepts the following arguments:

* `request` is a lua table that represent your request, it may contain the following keys:

 - `verb` is the request method, such as 'PUT', 'GET', and is required.

 - `uri` is the url encoded uri, it may contain query string depends on whether you specified `args` or not, and is required.

 - `args` is a lua table which contain the query parameters, if you have contained query string in `uri`, you can not specify this key.

 - `headers` is a lua table contains request headers, it must contain the 'Host' header, and is required.

 - `body` is a string contains the request body, it is optional. if provied, the method will calculate the SHA256 of the body content, and set the 'X-Amz-Content-SHA256' header. If you do not care about the integrity of the payload, you just do not include this key in the `request` lua table.


* `opts` is a lua table contains some optional argument, can be omited. You can specify the following optonal arguments:

 - `presign` if set to `true`, the signature will be add to query string, otherwise the signature will be contained in 'Authorization header'.

 - `sign_payload` if set to `true`, the 'X-Amz-Content-SHA256' header will be add to the signing process.

 - `headers_not_to_sign` is a list of headers which is not need to be signed.


The return values depend on the following cases:

1. if succeed, the method will return a lua table which contains some intermidiate values used in the
signing process, it is usefull for debuging.

2. If something go wrong, this method will return an error code and an error message.

[Back to TOC](#table-of-contents)

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
