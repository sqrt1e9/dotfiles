;; extends

; Modifier keywords
[
  "public" "protected" "private"
  "abstract" "static" "final"
  "default" "sealed" "non-sealed"
  "transient" "volatile" "strictfp"
  "synchronized" "native"
] @keyword.modifier

; Type declaration keywords
[ "class" "interface" "enum" "record" "@interface" ] @keyword.type

; Extends, implements, permits
[ "extends" "implements" "permits" ] @keyword

; Class/interface/enum/etc. names
(class_declaration name: (identifier) @type.definition)
(interface_declaration name: (identifier) @type.definition)
(enum_declaration name: (identifier) @type.definition)
(record_declaration name: (identifier) @type.definition)
(annotation_type_declaration name: (identifier) @type.definition)

