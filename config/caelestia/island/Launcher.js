// Recursive descent keeps calculator input separate from executable JavaScript.
function calculate(input) {
    const source = input.replace(/×/g, '*').replace(/÷/g, '/').replace(/−/g, '-').replace(/\*\*/g, '^');
    const tokens = source.match(/(?:\d*\.\d+|\d+\.?\d*)(?:e[+-]?\d+)?|[()+\-*/^%]|[a-z]+/gi) || [];
    if (tokens.join('').toLowerCase() !== source.replace(/\s/g, '').toLowerCase())
        throw new Error('Invalid expression');
    let i = 0;
    function primary() {
        const token = tokens[i++];
        let value;
        if (token === '(') {
            value = sum();
            if (tokens[i++] !== ')') throw new Error('Missing parenthesis');
        } else if (token && /^(pi|e)$/i.test(token)) {
            value = token.toLowerCase() === 'pi' ? Math.PI : Math.E;
        } else if (token && /^\d|^\.\d/.test(token)) {
            value = Number(token);
        } else {
            throw new Error('Expected number');
        }
        while (tokens[i] === '%') { i++; value /= 100; }
        return value;
    }
    function power() {
        const value = primary();
        if (tokens[i] === '^') { i++; return Math.pow(value, unary()); }
        return value;
    }
    function unary() {
        if (tokens[i] === '+') { i++; return unary(); }
        if (tokens[i] === '-') { i++; return -unary(); }
        return power();
    }
    function product() {
        let value = unary();
        while (tokens[i] === '*' || tokens[i] === '/') {
            const op = tokens[i++], right = unary();
            value = op === '*' ? value * right : value / right;
        }
        return value;
    }
    function sum() {
        let value = product();
        while (tokens[i] === '+' || tokens[i] === '-') {
            const op = tokens[i++], right = product();
            value = op === '+' ? value + right : value - right;
        }
        return value;
    }
    const result = sum();
    if (i !== tokens.length || !Number.isFinite(result)) throw new Error('Invalid result');
    return result;
}

const units = {};
function unit(names, dimension, scale, offset) {
    names.split('|').forEach(name => units[name] = { dimension: dimension, scale: scale, offset: offset || 0 });
}
unit('m|meter|meters|metre|metres', 'length', 1);
unit('km|kilometer|kilometers', 'length', 1000);
unit('cm|centimeter|centimeters', 'length', 0.01);
unit('mm|millimeter|millimeters', 'length', 0.001);
unit('in|inch|inches', 'length', 0.0254);
unit('ft|foot|feet', 'length', 0.3048);
unit('yd|yard|yards', 'length', 0.9144);
unit('mi|mile|miles', 'length', 1609.344);
unit('kg|kilogram|kilograms', 'mass', 1);
unit('g|gram|grams', 'mass', 0.001);
unit('mg', 'mass', 0.000001);
unit('lb|lbs|pound|pounds', 'mass', 0.45359237);
unit('oz|ounce|ounces', 'mass', 0.028349523125);
unit('s|sec|second|seconds', 'time', 1);
unit('min|minute|minutes', 'time', 60);
unit('h|hr|hour|hours', 'time', 3600);
unit('day|days', 'time', 86400);
unit('week|weeks', 'time', 604800);
unit('l|liter|liters|litre|litres', 'volume', 1);
unit('ml', 'volume', 0.001);
unit('c|°c|celsius', 'temperature', 1, 273.15);
unit('f|°f|fahrenheit', 'temperature', 5 / 9, 273.15 - 32 * 5 / 9);
unit('k|kelvin', 'temperature', 1);
['b', 'kb', 'mb', 'gb', 'tb'].forEach((name, i) => unit(name, 'data', Math.pow(1000, i)));
['kib', 'mib', 'gib', 'tib'].forEach((name, i) => unit(name, 'data', Math.pow(1024, i + 1)));

function format(value) {
    return Number(value.toPrecision(12)).toString();
}

function appResults(query, ranked, allApps, specialPrefix) {
    const normalized = query.trim().replace(/\s+/g, ' ').toLocaleLowerCase();
    if (!normalized || (specialPrefix && normalized.startsWith(`${specialPrefix.toLocaleLowerCase()} `)))
        return ranked;

    const seen = new Set(ranked.map(app => app.id ?? app.name));
    const terms = normalized.split(' ');
    const aliases = allApps.filter(app => {
        const id = app.id ?? app.name;
        if (seen.has(id)) return false;

        const fields = [
            app.name,
            app.genericName,
            app.comment,
            app.id,
            app.execString,
            app.startupClass,
            app.categories,
            app.keywords
        ];
        const searchable = fields.flatMap(value => Array.isArray(value) ? value : [value])
            .filter(Boolean).join(' ').toLocaleLowerCase();
        return terms.every(term => searchable.includes(term));
    });

    aliases.sort((a, b) => String(a.name ?? '').localeCompare(String(b.name ?? ''), undefined, { sensitivity: 'base' }));
    return [...ranked, ...aliases];
}

function answer(query) {
    const text = query.trim();
    const conversion = text.match(/^(.+?)\s*([a-z°]+)\s+(?:to|in)\s+([a-z°]+)$/i);
    try {
        if (conversion) {
            const from = units[conversion[2].toLowerCase()], to = units[conversion[3].toLowerCase()];
            if (!from || !to || from.dimension !== to.dimension) return null;
            const value = (calculate(conversion[1]) * from.scale + from.offset - to.offset) / to.scale;
            if (!Number.isFinite(value)) return null;
            return { name: format(value) + ' ' + conversion[3], value: format(value), desc: text, kind: 'Conversion' };
        }
        if (!/^[\d.(+\-]/.test(text) && !/^(pi|e)\s*[+\-*/^%]/i.test(text)) return null;
        if (!/[+\-*/^%×÷−()]/.test(text)) return null;
        const value = format(calculate(text));
        return { name: value, value: value, desc: text, kind: 'Calculator' };
    } catch (_) {
        return null;
    }
}

if (typeof module !== 'undefined') module.exports = { calculate, answer, appResults };
