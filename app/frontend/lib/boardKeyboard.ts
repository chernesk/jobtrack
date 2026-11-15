import type { KeyboardCoordinateGetter } from "@dnd-kit/core";

export type Direction = "left" | "right" | "up" | "down";

interface Box {
  left: number;
  top: number;
  width: number;
  height: number;
}

export interface Target<Id> {
  id: Id;
  box: Box;
}

const center = (box: Box) => ({ x: box.left + box.width / 2, y: box.top + box.height / 2 });

// By default dnd-kit's keyboard sensor nudges the card a few pixels per arrow key,
// which never reaches another column. Instead, each arrow jumps to the nearest drop
// target (card or column) lying in that direction.
export function nearestTarget<Id>(
  direction: Direction,
  from: Box,
  targets: Target<Id>[],
): Target<Id> | null {
  const origin = center(from);
  const inDirection = targets.filter(({ box }) => {
    const c = center(box);
    switch (direction) {
      case "left":
        return c.x < origin.x - 1;
      case "right":
        return c.x > origin.x + 1;
      case "up":
        return c.y < origin.y - 1;
      case "down":
        return c.y > origin.y + 1;
    }
  });

  let best: Target<Id> | null = null;
  let bestDistance = Infinity;
  for (const target of inDirection) {
    const c = center(target.box);
    // Weight the off-axis distance more, so "right" prefers the card beside you
    // over one that is closer in a straight line but far above or below.
    const horizontal = direction === "left" || direction === "right";
    const along = horizontal ? Math.abs(c.x - origin.x) : Math.abs(c.y - origin.y);
    const across = horizontal ? Math.abs(c.y - origin.y) : Math.abs(c.x - origin.x);
    const distance = along + across * 2;
    if (distance < bestDistance) {
      best = target;
      bestDistance = distance;
    }
  }
  return best;
}

const KEY_TO_DIRECTION: Record<string, Direction | undefined> = {
  ArrowLeft: "left",
  ArrowRight: "right",
  ArrowUp: "up",
  ArrowDown: "down",
};

export const boardCoordinates: KeyboardCoordinateGetter = (event, { context }) => {
  const direction = KEY_TO_DIRECTION[event.code];
  const { active, collisionRect, droppableRects, droppableContainers } = context;
  if (!direction || !active || !collisionRect) return undefined;
  event.preventDefault();

  const targets: Target<string | number>[] = [];
  for (const container of droppableContainers.getEnabled()) {
    const rect = droppableRects.get(container.id);
    if (container.id !== active.id && rect) targets.push({ id: container.id, box: rect });
  }

  const next = nearestTarget(direction, collisionRect, targets);
  return next ? { x: next.box.left, y: next.box.top } : undefined;
};
