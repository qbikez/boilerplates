import { main } from "./index";

describe("test fixture", () => {
  it("should work", () => {
    const exitCode = main(["a"]);
    expect(exitCode).toBe(0);
  });
});
