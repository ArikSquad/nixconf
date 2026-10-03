// LRC and enhanced LRC timestamps are expressed in seconds.
function timestamp(minutes, seconds) {
    return Number(minutes) * 60 + Number(seconds);
}
function distributeWords(line, endTime, segments) {
    const timedSegments = segments.length ? segments : [{time: line.time, text: line.text}];
    const words = [];
    timedSegments.forEach((segment, index) => {
        const tokens = segment.text.match(/\S+/g) || [];
        if (!tokens.length) return;
        const start = Number(segment.time);
        let end = index + 1 < timedSegments.length ? Number(timedSegments[index + 1].time) : endTime;
        if (!(end > start)) end = start + 0.12 * tokens.length;
        const weights = tokens.map(token => Math.max(1, token.length));
        const totalWeight = weights.reduce((sum, weight) => sum + weight, 0);
        let elapsedWeight = 0;
        tokens.forEach((token, tokenIndex) => {
            const wordStart = start + (end - start) * elapsedWeight / totalWeight;
            elapsedWeight += weights[tokenIndex];
            const wordEnd = start + (end - start) * elapsedWeight / totalWeight;
            words.push({time: wordStart, endTime: wordEnd, text: token});
        });
    });
    return words;
}
function parse(source, trackDuration) {
    const lines = [];
    if (typeof source !== "string" || !source) return lines;
    const offset = source.match(/\[offset:([+-]?\d+)\]/i);
    const shift = offset ? Number(offset[1]) / 1000 : 0;
    source.split(/\r?\n/).forEach(raw => {
        const stamps = [];
        const stampPattern = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
        let stamp;
        while ((stamp = stampPattern.exec(raw)) !== null)
            stamps.push({minutes: stamp[1], seconds: stamp[2]});
        if (!stamps.length) return;
        const body = raw.replace(/\[[^\]]*\]/g, "").trim();
        const words = [];
        const pattern = /<(\d+):(\d+(?:\.\d+)?)>([^<]*)/g;
        let word;
        while ((word = pattern.exec(body)) !== null) {
            if (word[3].trim()) words.push({time: timestamp(word[1], word[2]) + shift, text: word[3].trim()});
        }
        stamps.forEach(stamp => lines.push({time: timestamp(stamp.minutes, stamp.seconds) + shift,
            text: body.replace(/<[^>]*>/g, "").trim(), words: stamps.length === 1 ? words : []}));
    });
    lines.sort((a, b) => a.time - b.time);
    lines.forEach((line, index) => {
        const nextTime = index + 1 < lines.length ? lines[index + 1].time : Number(trackDuration);
        const naturalEnd = nextTime > line.time ? nextTime : line.time + 4;
        line.endTime = Math.max(line.time + 0.35, Math.min(naturalEnd, line.time + 6));
        line.words = distributeWords(line, line.endTime, line.words);
    });
    return lines;
}
function activeLine(lines, position) {
    let index = -1;
    for (let i = 0; i < lines.length && lines[i].time <= position; ++i) index = i;
    return index;
}
