import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

import window from 'ember-window-mock';
import { TrackedArray } from 'tracked-built-ins';

export default class RecentFilesService extends Service {
  @tracked recentFiles = new TrackedArray<string>([]);

  constructor(properties: object) {
    super(properties);

    let recentFilesString = window.localStorage.getItem('recent-files');

    if (recentFilesString) {
      try {
        this.recentFiles = new TrackedArray(
          JSON.parse(recentFilesString).reduce(function (
            recentFiles: string[],
            fileString: string,
          ) {
            try {
              new URL(fileString);
              recentFiles.push(fileString);
            } catch (e) {
              console.log(
                `Ignoring non-URL recent file from storage: ${fileString}`,
              );
            }
            return recentFiles;
          }, []),
        );
      } catch (e) {
        console.log('Error restoring recent files', e);
      }
    }
  }

  removeRecentFile(file: string) {
    let index = this.recentFiles.findIndex((f) => f === file);
    if (index === -1) {
      return;
    }
    while (index !== -1) {
      this.recentFiles.splice(index, 1);
      index = this.recentFiles.findIndex((f) => f === file);
    }
    this.persistRecentFiles();
  }

  addRecentFile(file: string) {
    const existingIndex = this.recentFiles.indexOf(file);

    if (existingIndex > -1) {
      this.recentFiles.splice(existingIndex, 1);
    }

    this.recentFiles.unshift(file);
    this.persistRecentFiles();
  }

  persistRecentFiles() {
    window.localStorage.setItem(
      'recent-files',
      JSON.stringify(this.recentFiles),
    );
  }
}
