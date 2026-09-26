import { Log } from '@microsoft/sp-core-library';
import * as React from 'react';

import styles from './ColorCoded.module.scss';

export interface IColorCodedProps {
  text: string;
}

const LOG_SOURCE: string = 'ColorCoded';

export default class ColorCoded extends React.Component<IColorCodedProps> {
  public componentDidMount(): void {
    Log.info(LOG_SOURCE, 'React Element: ColorCoded mounted');
  }

  public componentWillUnmount(): void {
    Log.info(LOG_SOURCE, 'React Element: ColorCoded unmounted');
  }

  public render(): React.ReactElement<IColorCodedProps> {
    return (
      <div className={styles.colorCoded}>
        { this.props.text }
      </div>
    );
  }
}
