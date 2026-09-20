// Pure state arbitration, shared by every display and exercised without hardware.
function resolve(page, transient, popup) {
    if (popup) return "notification";
    if (transient) return transient;
    return page || "idle";
}
function validPage(page) {
    return ["idle", "more", "overview", "media", "controls", "calendar", "weather", "performance", "timer", "notifications", "system"].indexOf(page) !== -1;
}
function remaining(deadline, now) { return Math.max(0, Math.ceil((deadline - now) / 1000)); }
function monthCells(year, month) {
    const offset = (new Date(year, month, 1).getDay() + 6) % 7;
    return Array.from({length: 42}, (_, i) => {
        const date = new Date(year, month, i - offset + 1);
        return {day: date.getDate(), current: date.getMonth() === month, year: date.getFullYear(), month: date.getMonth()};
    });
}
function visibleMonthCells(year, month) {
    const cells = monthCells(year, month);
    return cells.slice(0, cells.slice(35).some(day => day.current) ? 42 : 35);
}
if (typeof module !== "undefined") module.exports = {resolve, validPage, remaining, monthCells, visibleMonthCells};
