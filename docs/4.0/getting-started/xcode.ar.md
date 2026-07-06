# Xcode

تتناول هذه الصفحة بعض النصائح والحيل لاستخدام Xcode. إذا كنت تستخدم بيئة تطوير مختلفة، فيمكنك تخطي هذا.

## دليل عمل مخصّص (Custom Working Directory)

بشكل افتراضي، سيُشغّل Xcode مشروعك من مجلد _DerivedData_. هذا المجلد ليس نفس المجلد الجذري لمشروعك (حيث يوجد ملف _Package.swift_ الخاص بك). وهذا يعني أن Vapor لن يتمكن من العثور على ملفات ومجلدات مثل _.env_ أو _Public_.

يمكنك معرفة أن هذا يحدث إذا رأيت التحذير التالي عند تشغيل تطبيقك.

```fish
[ WARNING ] No custom working directory set for this scheme, using /path/to/DerivedData/project-abcdef/Build/
```

لإصلاح هذا، عيّن دليل عمل مخصّصاً في مخطط Xcode لمشروعك.

أولاً، حرّر مخطط مشروعك بالنقر على محدّد المخطط (scheme selector) بجانب زرَّي التشغيل والإيقاف.

![Xcode Scheme Area](../images/xcode-scheme-area.png)

اختر _Edit Scheme..._ من القائمة المنسدلة.

![Xcode Scheme Menu](../images/xcode-scheme-menu.png)

في محرّر المخطط، اختر إجراء _App_ وعلامة التبويب _Options_. حدّد _Use custom working directory_ وأدخل المسار إلى المجلد الجذري لمشروعك.

![Xcode Scheme Options](../images/xcode-scheme-options.png)

يمكنك الحصول على المسار الكامل إلى جذر مشروعك عن طريق تشغيل `pwd` من نافذة طرفية مفتوحة هناك.

```sh
# get path to this folder
pwd
```

من المفترض أن ترى مخرجات مشابهة لما يلي.

```
/path/to/project
```
