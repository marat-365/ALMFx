declare interface IItemActionsCommandSetStrings {
  Command1: string;
  Command2: string;
}

declare module 'ItemActionsCommandSetStrings' {
  const strings: IItemActionsCommandSetStrings;
  export = strings;
}
