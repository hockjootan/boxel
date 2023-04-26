import type { TemplateOnlyComponent } from '@ember/component/template-only';
import { svgJar } from '../../helpers/svg-jar';
import { concat } from '@ember/helper';
import cn from '../../helpers/cn';

export interface Signature {
  Element: HTMLButtonElement;
  Args: {
    variant?: string;
    class?: string;
    icon?: string;
    width?: string;
    height?: string;
    tooltip?: string;
  };
  Blocks: {
    default: [];
  };
}

const IconButton: TemplateOnlyComponent<Signature> = <template>
  <button
    class={{cn
      'boxel-icon-button'
      (if @variant (concat 'boxel-icon-button--' @variant))
      (if @tooltip 'boxel-icon-button--tooltip')
      @class
    }}
    data-hover={{@tooltip}}
    ...attributes
  >
    {{#if @icon}}
      {{svgJar
        @icon
        width=(if @width @width '16px')
        height=(if @height @height '16px')
      }}
    {{/if}}
  </button>
</template>;

export default IconButton;