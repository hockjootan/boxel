// This file is auto-generated by 'pnpm rebuild:icons'
import type { TemplateOnlyComponent } from '@ember/component/template-only';

import type { Signature } from './types.ts';

const IconComponent: TemplateOnlyComponent<Signature> = <template>
  <svg
    xmlns='http://www.w3.org/2000/svg'
    width='50'
    height='60'
    viewBox='0 0 50 60'
    ...attributes
  ><g fill='none' stroke-linecap='round' stroke-linejoin='round'><path
        d='M27.5 5H10a5 5 0 0 0-5 5v40a5 5 0 0 0 5 5h30a5 5 0 0 0 5-5V22.5z'
      /><path
        fill='var(--icon-color, #000)'
        d='M10 5a5 5 0 0 0-5 5v40a5 5 0 0 0 5 5h30a5 5 0 0 0 5-5V22.5L27.5 5zm0-5h17.5a5 5 0 0 1 3.536 1.464l17.5 17.5A5 5 0 0 1 50 22.5V50c0 5.514-4.486 10-10 10H10C4.486 60 0 55.514 0 50V10C0 4.486 4.486 0 10 0z'
      /><path
        stroke='var(--icon-color, #000)'
        stroke-width='5'
        d='M27.5 5v17.5H45'
      /></g></svg>
</template>;

// @ts-expect-error this is the only way to set a name on a Template Only Component currently
IconComponent.name = 'File';
export default IconComponent;
