export {};

export function main(args: string[]): number {
  console.log("hello world!");

  return 0;
}

process.exitCode = main(process.argv);
