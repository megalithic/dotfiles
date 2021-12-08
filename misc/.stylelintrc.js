module.exports = {
  extends: [
    'stylelint-config-standard',
  ],
  rules: {
    'at-rule-empty-line-before': [
      'always', {
        except: ['blockless-after-blockless', 'blockless-after-same-name-blockless', 'first-nested'],
        ignore: ['after-comment', 'inside-block'],
        ignoreAtRules: ['apply', 'screen', 'font-face', 'nest'],
      },
    ],
    'at-rule-no-unknown': [
      true, {
        ignoreAtRules: ['layer', 'tailwind', 'variants', 'responsive', 'apply', 'screen'],
      },
    ],
    'property-no-unknown': [
      true, {
        ignoreProperties: ['font-path']
      },
    ],
    'selector-nested-pattern': '^&',
  },
}
