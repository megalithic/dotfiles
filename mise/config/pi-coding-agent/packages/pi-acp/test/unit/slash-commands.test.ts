import test from 'node:test'
import assert from 'node:assert/strict'
import {
  expandSlashCommand,
  parseCommandArgs,
  substituteArgs,
  toAvailableCommands
} from '../../src/acp/slash-commands.js'

test('parseCommandArgs: handles quotes', () => {
  assert.deepEqual(parseCommandArgs('a b'), ['a', 'b'])
  assert.deepEqual(parseCommandArgs("'a b' c"), ['a b', 'c'])
  assert.deepEqual(parseCommandArgs('"a b" c'), ['a b', 'c'])
})

test('substituteArgs: replaces $1.. and $@', () => {
  assert.equal(substituteArgs('x=$1 y=$2 all=$@', ['one', 'two']).trim(), 'x=one y=two all=one two')
  assert.equal(substituteArgs('$3', ['one']).trim(), '')
})

test('expandSlashCommand: expands known command', () => {
  const cmds = [{ name: 'hello', description: '(user)', content: 'Say hi to $1', source: '(user)' }]

  assert.equal(expandSlashCommand('/hello world', cmds as any), 'Say hi to world')
  assert.equal(expandSlashCommand('/unknown world', cmds as any), '/unknown world')
  assert.equal(expandSlashCommand('not a command', cmds as any), 'not a command')
})

test('toAvailableCommands: de-dupes by name (first wins)', () => {
  const cmds = [
    { name: 'x', description: 'first', content: '1', source: '(user)' },
    { name: 'x', description: 'second', content: '2', source: '(project)' }
  ]

  assert.deepEqual(toAvailableCommands(cmds as any), [{ name: 'x', description: 'first' }])
})
