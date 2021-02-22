import Component from '@glimmer/component';
import { schedule } from '@ember/runloop';
import Ember from 'ember';

const { VOLATILE_TAG, consumeTag } = Ember.__loader.require(
  '@glimmer/validator'
);

class Sprite {
  element;
  id;
  initialBounds = null;
  finalBounds = null;

  constructor(element) {
    this.element = element;
  }
}

const INSERTED = Symbol('inserted');
const REMOVED = Symbol('removed');
const KEPT = Symbol('kept');
// const SENT = new Symbol('sent');
// const RECEIVED = new Symbol('received');

function createSprite(spriteModifier, type) {
  let sprite = new Sprite(spriteModifier.element);
  sprite.id = spriteModifier.id;
  if (type === INSERTED) {
    sprite.finalBounds = spriteModifier.currentPosition.element;
  }
  if (type === REMOVED) {
    sprite.initialBounds = spriteModifier.currentPosition.element;
  }
  if (type === KEPT) {
    sprite.initialBounds = spriteModifier.lastPosition.element;
    sprite.finalBounds = spriteModifier.currentPosition.element;
  }
  sprite.initialBoundsString = JSON.stringify(sprite.initialBounds);
  sprite.finalBoundsString = JSON.stringify(sprite.finalBounds);

  return sprite;
}
export default class AnimationContextComponent extends Component {
  registered = new Set();

  freshlyAdded = new Set();
  freshlyRemoved = new Set();
  freshlyChanged = new Set();

  orphansElement; //set by template

  get renderDetector() {
    consumeTag(VOLATILE_TAG);
    schedule('afterRender', this, 'maybeTransition');
    return undefined;
  }

  register(spriteModifier) {
    this.registered.add(spriteModifier);
    this.freshlyAdded.add(spriteModifier);
  }

  unregister(spriteModifier) {
    this.registered.delete(spriteModifier);
    this.freshlyRemoved.add(spriteModifier);
  }

  maybeTransition() {
    for (let spriteModifier of this.registered) {
      if (spriteModifier.checkForChanges()) {
        this.freshlyChanged.add(spriteModifier);
      }
    }
    this.simulateTransition();
  }

  simulateTransition() {
    if (
      this.freshlyChanged.size === 0 &&
      this.freshlyAdded.size === 0 &&
      this.freshlyRemoved.size === 0
    ) {
      return;
    }
    let changeset = {
      insertedSprites: new Set(),
      removedSprites: new Set(),
      keptSprites: new Set(),
      sentSprites: new Set(),
      receivedSprites: new Set(),
    };

    for (let spriteModifier of this.freshlyAdded) {
      changeset.insertedSprites.add(createSprite(spriteModifier, INSERTED));
    }
    this.freshlyAdded.clear();

    for (let spriteModifier of this.freshlyRemoved) {
      changeset.removedSprites.add(createSprite(spriteModifier, REMOVED));
    }
    this.freshlyRemoved.clear();

    for (let spriteModifier of this.freshlyChanged) {
      changeset.keptSprites.add(createSprite(spriteModifier, KEPT));
    }
    this.freshlyChanged.clear();

    if (this.args.use && !this.isAnimating) {
      this.isAnimating = true;
      this.logChangeset(changeset); // For debugging
      let animation = this.args.use(changeset, this.orphansElement);
      animation.then(() => {
        this.isAnimating = false;
      });
    }
  }

  logChangeset(changeset) {
    let contextId = this.args.id;
    function row(type, sprite) {
      return {
        context: contextId,
        type,
        spriteId: sprite.id,
        initialBounds: sprite.initialBounds
          ? JSON.stringify(sprite.initialBounds)
          : null,
        finalBounds: sprite.finalBounds
          ? JSON.stringify(sprite.finalBounds)
          : null,
      };
    }
    let tableRows = [];
    for (let type of ['inserted', 'removed', 'kept', 'sent', 'received']) {
      for (let sprite of changeset[`${type}Sprites`]) {
        tableRows.push(row(type, sprite));
      }
    }
    console.table(tableRows);
  }
}