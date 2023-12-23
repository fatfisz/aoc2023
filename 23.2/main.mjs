import fs from 'node:fs';

const data = fs.readFileSync(process.argv[2] + '.in', 'utf8').trim().split('\n');

const maxSize = 256;

const edges = Array.from(new Array(maxSize * maxSize), () => []);

const width = data[0].length;
const height = data.length;

const stack = [];

const onStack = [];

for (let y = 1; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
        if (data[y][x] === '#')
            continue;

        if (x > 0 && data[y][x - 1] !== '#')
            pushEdge(getVertex(x - 1, y), getVertex(x, y));

        if (data[y - 1][x] !== '#')
            pushEdge(getVertex(x, y - 1), getVertex(x, y));
    }
}

for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
        const vertex = getVertex(x, y);
        if (edges[vertex].length === 2) {
            const a = edges[vertex][0];
            const b = edges[vertex][1];

            updateLength(a.to, vertex, b.to, a.len + b.len);
            updateLength(b.to, vertex, a.to, a.len + b.len);
        }
    }
}

let maxPathLen = 0;

pushIfNotOnStack(getVertex(1, 0), 0, 0);

while (stack.length > 0) {
    const lastEdge = stack[stack.length - 1];
    if (lastEdge.index == edges[lastEdge.from].length)
        pop();
    else {
        const edge = edges[lastEdge.from][lastEdge.index];
        lastEdge.index += 1;
        pushIfNotOnStack(edge.to, 0, lastEdge.len + edge.len);
    }
}

console.log(maxPathLen);

function pushEdge(a, b) {
    edges[a].push({ to: b, len: 1 });
    edges[b].push({ to: a, len: 1 });
}

function updateLength(from, to, newTo, len) {
    const edge = edges[from].find((edge) => edge.to === to);
    edge.to = newTo;
    edge.len = len;
}

function getVertex(x, y) {
    return 1 + x + y * width;
}

function pushIfNotOnStack(from, index, len) {
    if (onStack[from])
        return;

    if (isFinal(from))
        maxPathLen = Math.max(maxPathLen, len);

    stack.push({ from, index, len });
    onStack[from] = true;
}

function pop() {
    onStack[stack.pop().from] = false;
}

function isFinal(vertex) {
    return vertex === getVertex(width - 2, height - 1);
}
