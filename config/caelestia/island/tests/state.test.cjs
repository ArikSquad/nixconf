const {test} = require('node:test');
const assert = require('node:assert/strict');
const state = require('../State.js');
test('notifications interrupt events, then restore the selected page', () => {
    assert.equal(state.resolve('calendar', 'volume', {}), 'notification');
    assert.equal(state.resolve('calendar', 'volume', null), 'volume');
    assert.equal(state.resolve('calendar', '', null), 'calendar');
    assert.equal(state.resolve('', '', null), 'idle');
});
test('IPC rejects unknown pages', () => {
    assert.equal(state.validPage('more'), true);
    assert.equal(state.validPage('calendar'), true);
    assert.equal(state.validPage('shutdown'), false);
});
test('timer uses a deadline so suspend or delayed ticks do not extend it', () => {
    assert.equal(state.remaining(60100, 100), 60);
    assert.equal(state.remaining(60100, 59101), 1);
    assert.equal(state.remaining(60100, 90000), 0);
});
test('calendar aligns Monday first and handles leap years and year boundaries', () => {
    const feb = state.monthCells(2024, 1);
    assert.equal(feb.length, 42);
    assert.deepEqual(feb[0], {day: 29, current: false, year: 2024, month: 0});
    assert.deepEqual(feb[3], {day: 1, current: true, year: 2024, month: 1});
    assert.equal(feb.filter(d => d.current).length, 29);
    assert.equal(state.monthCells(2025, 1).filter(d => d.current).length, 28);
    assert.deepEqual(state.monthCells(2026, 11).at(-1), {day: 10, current: false, year: 2027, month: 0});
});
test('calendar only reserves a sixth week when the month needs it', () => {
    assert.equal(state.visibleMonthCells(2026, 1).length, 35);
    assert.equal(state.visibleMonthCells(2026, 2).length, 42);
});
