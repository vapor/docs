# النشر باستخدام Nginx

إن Nginx هو خادم HTTP ووكيل سريع للغاية ومُختبَر بشدة وسهل الإعداد. وبينما يدعم Vapor خدمة طلبات HTTP مباشرة سواء بـ TLS أو بدونه، فإن الوكالة خلف Nginx يمكن أن توفر أداءً وأماناً وسهولة استخدام أعلى.

!!! note "ملاحظة"
    نوصي بوضع خوادم Vapor لـ HTTP خلف وكيل Nginx.

## نظرة عامة

ماذا يعني أن نجعل خادم HTTP خلف وكيل؟ باختصار، يعمل الوكيل كوسيط بين الإنترنت العام وخادم HTTP الخاص بك. تصل الطلبات إلى الوكيل ثم يرسلها إلى Vapor.

من الميزات المهمة لهذا الوكيل الوسيط أنه يستطيع تعديل الطلبات أو حتى إعادة توجيهها. على سبيل المثال، يمكن للوكيل أن يشترط على العميل استخدام TLS (‏https)، أو أن يحدّ من معدل الطلبات، أو حتى أن يقدّم الملفات العامة دون التواصل مع تطبيق Vapor الخاص بك.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### مزيد من التفاصيل

المنفذ الافتراضي لاستقبال طلبات HTTP هو المنفذ `80` (والمنفذ `443` لـ HTTPS). عندما تربط خادم Vapor بالمنفذ `80`، فإنه سيستقبل طلبات HTTP التي تصل إلى خادمك ويستجيب لها مباشرة. وعند إضافة وكيل مثل Nginx، فإنك تربط Vapor بمنفذ داخلي، مثل المنفذ `8080`.

!!! note "ملاحظة"
    المنافذ الأكبر من 1024 لا تتطلب `sudo` للربط بها.

عندما يكون Vapor مربوطاً بمنفذ غير `80` أو `443`، فإنه لن يكون قابلاً للوصول من الإنترنت الخارجي. عندئذ تربط Nginx بالمنفذ `80` وتُعِدّه لتوجيه الطلبات إلى خادم Vapor المربوط بالمنفذ `8080` (أو أي منفذ اخترته).

وهذا كل شيء. فإذا كان Nginx مُعَدّاً بشكل صحيح، فسترى تطبيق Vapor الخاص بك يستجيب للطلبات على المنفذ `80`. يقوم Nginx بوكالة الطلبات والاستجابات بشكل غير مرئي.

## تثبيت Nginx

الخطوة الأولى هي تثبيت Nginx. من الجوانب الرائعة في Nginx الكمّ الهائل من موارد المجتمع والتوثيق المحيطة به. ولهذا السبب، لن نخوض هنا في تفاصيل كثيرة حول تثبيت Nginx، إذ يكاد يكون هناك بشكل شبه مؤكد شرح خاص بمنصتك ونظام تشغيلك ومزوّدك.

شروحات:

- [كيفية تثبيت Nginx على Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [كيفية تثبيت Nginx على Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [كيفية تثبيت Nginx على CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [كيفية تثبيت Nginx على Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [كيفية نشر Nginx على Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### مديرو الحزم

يمكن تثبيت Nginx عبر مديري الحزم على Linux.

#### Ubuntu

```sh
sudo apt-get update
sudo apt-get install nginx
```

#### CentOS و Amazon Linux

```sh
sudo yum install nginx
```

#### Fedora

```sh
sudo dnf install nginx
```

### التحقق من التثبيت

تحقق من أن Nginx قد ثُبّت بشكل صحيح عن طريق زيارة عنوان IP الخاص بخادمك في المتصفح

```
http://server_domain_name_or_IP
```

### الخدمة

يمكن تشغيل الخدمة أو إيقافها.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## تشغيل Vapor

يمكن تشغيل Nginx وإيقافه باستخدام أوامر `sudo service nginx ...`. ستحتاج إلى شيء مماثل لتشغيل خادم Vapor وإيقافه.

هناك طرق كثيرة للقيام بذلك، وهي تعتمد على المنصة التي تنشر عليها. اطّلع على تعليمات [Supervisor](supervisor.md) لإضافة أوامر لتشغيل تطبيق Vapor الخاص بك وإيقافه.

## إعداد الوكيل

توجد ملفات الإعداد للمواقع المُفعَّلة في `/etc/nginx/sites-enabled/`.

أنشئ ملفاً جديداً أو انسخ القالب التوضيحي من `/etc/nginx/sites-available/` للبدء.

فيما يلي مثال على ملف إعداد لمشروع Vapor يُسمّى `Hello` موجود في المجلد الرئيسي.

```sh
server {
    server_name hello.com;
    listen 80;

    root /home/vapor/Hello/Public/;

    location @proxy {
        proxy_pass http://127.0.0.1:8080;
        proxy_pass_header Server;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 3s;
        proxy_read_timeout 10s;
    }
}
```

يفترض ملف الإعداد هذا أن مشروع `Hello` يرتبط بالمنفذ `8080` عند تشغيله في وضع الإنتاج.

### خدمة الملفات

يمكن لـ Nginx أيضاً أن يقدّم الملفات العامة دون سؤال تطبيق Vapor الخاص بك. وهذا يمكن أن يحسّن الأداء عن طريق تحرير عملية Vapor لأداء مهام أخرى تحت الحِمل الثقيل.

```sh
server {
    ...

    # Serve all public/static files via nginx and then fallback to Vapor for the rest
    location / {
        try_files $uri @proxy;
    }

    location @proxy {
        ...
    }
}
```

### TLS

إضافة TLS أمر بسيط نسبياً طالما أن الشهادات قد أُنشئت بشكل صحيح. لإنشاء شهادات TLS مجاناً، اطّلع على [Let's Encrypt](https://letsencrypt.org/getting-started/).

```sh
server {
    ...

    listen 443 ssl;

    ssl_certificate /etc/letsencrypt/live/hello.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/hello.com/privkey.pem;

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security max-age=15768000;

    ...

    location @proxy {
       ...
    }
}
```

الإعدادات أعلاه هي إعدادات صارمة نسبياً لـ TLS مع Nginx. بعض هذه الإعدادات ليست مطلوبة، لكنها تعزز الأمان.
