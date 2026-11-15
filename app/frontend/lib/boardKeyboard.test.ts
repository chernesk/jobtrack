import { nearestTarget, type Target } from "./boardKeyboard";

const box = (left: number, top: number) => ({ left, top, width: 100, height: 50 });

// Two columns side by side, two cards each.
const targets: Target<string>[] = [
  { id: "a1", box: box(0, 0) },
  { id: "a2", box: box(0, 60) },
  { id: "b1", box: box(200, 0) },
  { id: "b2", box: box(200, 60) },
];

describe("nearestTarget", () => {
  it("goes right to the card beside you, not the one diagonally below", () => {
    expect(nearestTarget("right", box(0, 0), targets)?.id).toBe("b1");
    expect(nearestTarget("right", box(0, 60), targets)?.id).toBe("b2");
  });

  it("goes left and vertically within a column", () => {
    expect(nearestTarget("left", box(200, 60), targets)?.id).toBe("a2");
    expect(nearestTarget("down", box(0, 0), targets)?.id).toBe("a2");
    expect(nearestTarget("up", box(200, 60), targets)?.id).toBe("b1");
  });

  it("returns null at the edge of the board", () => {
    expect(nearestTarget("left", box(0, 0), targets)).toBeNull();
    expect(nearestTarget("up", box(0, 0), targets)).toBeNull();
  });
});
