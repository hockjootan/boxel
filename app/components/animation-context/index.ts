import Component from '@glimmer/component';
import Ember from 'ember';
import { reads } from 'macro-decorators';
import Changeset from '../../models/changeset';
import { inject as service } from '@ember/service';
import { action } from '@ember/object';
import AnimationsService from '../../services/animations';
import { assert } from '@ember/debug';
import { getDocumentPosition } from '../../utils/measurement';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
const { VOLATILE_TAG, consumeTag } = Ember.__loader.require(
  '@glimmer/validator'
);

interface AnimationContextArgs {
  id: string | undefined;
  use: ((changeset: Changeset) => Promise<void>) | undefined;
}

export default class AnimationContextComponent extends Component<AnimationContextArgs> {
  @service declare animations: AnimationsService;
  @reads('args.id') id: string | undefined;

  element!: HTMLElement; //set by template
  orphansElement: HTMLElement | null = null; //set by template
  lastBounds: DOMRect | undefined;
  currentBounds: DOMRect | undefined;
  isInitialRenderCompleted = false;

  @reads('args.initialInsertion', false) initialInsertion: boolean | undefined;

  willDestroy(): void {
    super.willDestroy();
    this.animations.unregisterContext(this);
  }

  get renderDetector(): undefined {
    consumeTag(VOLATILE_TAG);
    this.animations.notifyContextRendering(this);
    return undefined;
  }

  @action didInsertEl(element: HTMLElement): void {
    this.element = element;
    this.animations.registerContext(this);
    this.trackPosition();
  }

  @action didInsertOrphansEl(element: HTMLElement): void {
    this.orphansElement = element;
  }

  trackPosition(): void {
    let { element } = this;
    assert(
      'animation context must be an HTML element',
      element instanceof HTMLElement
    );
    this.lastBounds = this.currentBounds;
    this.currentBounds = getDocumentPosition(element);
  }

  shouldAnimate(changeset: Changeset): boolean {
    return !!(
      changeset &&
      this.args.use &&
      (this.isInitialRenderCompleted || this.initialInsertion)
    );
  }

  clearOrphans(): void {
    let { orphansElement } = this;
    while (orphansElement && orphansElement.firstChild) {
      orphansElement.removeChild(orphansElement.firstChild);
    }
  }
}