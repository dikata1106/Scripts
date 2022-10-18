#!/bin/bash

function style-format {
  find $PWD -name '*.h' -or -name '*.c' -or -name '*.cpp' -or -name '*.cc' | \
  xargs clang-format -i -verbose -style="{BasedOnStyle: Google, \
  AllowShortFunctionsOnASingleLine: false, \
  AllowShortLoopsOnASingleLine: false, \
  AllowShortIfStatementsOnASingleLine: false, \
  IndentWidth: 4}"
}

function compile {
    clang *.c  -o $1 && echo "$1 compiled"
}

function run {
    ./$1
}

## alias usf='. ~/myStyleFormat.sh'
## alias sf='style-format'

# ---
# Language:        Cppz
# # BasedOnStyle:  Google
# AccessModifierOffset: -1
# AlignAfterOpenBracket: Align
# AlignConsecutiveAssignments: false
# AlignConsecutiveDeclarations: false
# AlignEscapedNewlines: Left
# AlignOperands:   true
# AlignTrailingComments: true
# AllowAllParametersOfDeclarationOnNextLine: true
# AllowShortBlocksOnASingleLine: false
# AllowShortCaseLabelsOnASingleLine: false
  # AllowShortFunctionsOnASingleLine: All
  # AllowShortIfStatementsOnASingleLine: true
  # AllowShortLoopsOnASingleLine: true
# AlwaysBreakAfterDefinitionReturnType: None
# AlwaysBreakAfterReturnType: None
# AlwaysBreakBeforeMultilineStrings: true
# AlwaysBreakTemplateDeclarations: true
# BinPackArguments: true
# BinPackParameters: true
# BraceWrapping:   
#   AfterClass:      false
#   AfterControlStatement: false
#   AfterEnum:       false
#   AfterFunction:   false
#   AfterNamespace:  false
#   AfterObjCDeclaration: false
#   AfterStruct:     false
#   AfterUnion:      false
#   AfterExternBlock: false
#   BeforeCatch:     false
#   BeforeElse:      false
#   IndentBraces:    false
#   SplitEmptyFunction: true
#   SplitEmptyRecord: true
#   SplitEmptyNamespace: true
# BreakBeforeBinaryOperators: None
# BreakBeforeBraces: Attach
# BreakBeforeInheritanceComma: false
# BreakBeforeTernaryOperators: true
# BreakConstructorInitializersBeforeComma: false
# BreakConstructorInitializers: BeforeColon
# BreakAfterJavaFieldAnnotations: false
# BreakStringLiterals: true
# ColumnLimit:     80
# CommentPragmas:  '^ IWYU pragma:'
# CompactNamespaces: false
# ConstructorInitializerAllOnOneLineOrOnePerLine: true
# ConstructorInitializerIndentWidth: 4
# ContinuationIndentWidth: 4
# Cpp11BracedListStyle: true
# DerivePointerAlignment: true
# DisableFormat:   false
# ExperimentalAutoDetectBinPacking: false
# FixNamespaceComments: true
# ForEachMacros:   
#   - foreach
#   - Q_FOREACH
#   - BOOST_FOREACH
# IncludeBlocks:   Preserve
# IncludeCategories: 
#   - Regex:           '^<ext/.*\.h>'
#     Priority:        2
#   - Regex:           '^<.*\.h>'
#     Priority:        1
#   - Regex:           '^<.*'
#     Priority:        2
#   - Regex:           '.*'
#     Priority:        3
# IncludeIsMainRegex: '([-_](test|unittest))?$'
# IndentCaseLabels: true
# IndentPPDirectives: None
# IndentWidth:     2
# IndentWrappedFunctionNames: false
# JavaScriptQuotes: Leave
# JavaScriptWrapImports: true
# KeepEmptyLinesAtTheStartOfBlocks: false
# MacroBlockBegin: ''
# MacroBlockEnd:   ''
# MaxEmptyLinesToKeep: 1
# NamespaceIndentation: None
# ObjCBlockIndentWidth: 2
# ObjCSpaceAfterProperty: false
# ObjCSpaceBeforeProtocolList: false
# PenaltyBreakAssignment: 2
# PenaltyBreakBeforeFirstCallParameter: 1
# PenaltyBreakComment: 300
# PenaltyBreakFirstLessLess: 120
# PenaltyBreakString: 1000
# PenaltyExcessCharacter: 1000000
# PenaltyReturnTypeOnItsOwnLine: 200
# PointerAlignment: Left
# RawStringFormats: 
#   - Delimiter:       pb
#     Language:        TextProto
#     BasedOnStyle:    google
# ReflowComments:  true
# SortIncludes:    true
# SortUsingDeclarations: true
# SpaceAfterCStyleCast: false
# SpaceAfterTemplateKeyword: true
# SpaceBeforeAssignmentOperators: true
# SpaceBeforeParens: ControlStatements
# SpaceInEmptyParentheses: false
# SpacesBeforeTrailingComments: 2
# SpacesInAngles:  false
# SpacesInContainerLiterals: true
# SpacesInCStyleCastParentheses: false
# SpacesInParentheses: false
# SpacesInSquareBrackets: false
# Standard:        Auto
# TabWidth:        8
# UseTab:          Never
# ...
