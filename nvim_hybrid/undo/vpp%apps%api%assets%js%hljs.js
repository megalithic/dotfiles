Vim�UnDo� �)��7����p�� p��-�p�I�ٴ��U�   1                                   \�8�    _�                             ����                                                                                                                                                                                                                                                                                                                                                             \�8�     �                 �               �               �                  �               5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        \�8�     �                 background: red;�               5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        \�8�     �                  5�_�                            ����                                                                                                                                                                                                                                                                                                                                                  V        \�8�     �                 5�_�                     1        ����                                                                                                                                                                                                                                                                                                                                                  V        \�8�    �       0   1   /    import hljs from 'highlight.js';       /hljs.registerLanguage("graphql", function (e) {   
  return {       aliases: ["gql"],       keywords: {   {      keyword: "query mutation subscription|10 type input schema directive interface union scalar fragment|10 enum on ...",          literal: "true false null"       },       contains: [         e.HASH_COMMENT_MODE,         e.QUOTE_STRING_MODE,         e.NUMBER_MODE,         {           className: "type",   "        begin: "[^\\w][A-Z][a-z]",           end: "\\W",           excludeEnd: !0,         },         {           className: "literal",   "        begin: "[^\\w][A-Z][A-Z]",           end: "\\W",           excludeEnd: !0,         },         {           className: "variable",           begin: "\\$",           end: "\\W",           excludeEnd: !0,         },         {           className: "keyword",           begin: "[.]{2}",           end: "\\.",         },         {           className: "meta",           begin: "@",           end: "\\W",           excludeEnd: !0,         },       ],       illegal: /([;<']|BEGIN)/,     };   });    5��