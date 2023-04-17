import StringCard from 'https://cardstack.com/base/string';
import TextAreaCard from 'https://cardstack.com/base/text-area';
import {
  Card,
  field,
  contains,
  linksTo,
} from 'https://cardstack.com/base/card-api';
import { Author } from './author';

export class BlogPost extends Card {
  @field title = contains(StringCard);
  @field slug = contains(StringCard);
  @field body = contains(TextAreaCard); // TODO: rich text
  @field authorBio = linksTo(Author);
}
