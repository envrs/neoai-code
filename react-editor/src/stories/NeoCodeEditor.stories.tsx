import type { Meta, StoryObj } from '@storybook/react';
import { NeoCodeEditor, NeoProvider } from '../components';
import React from 'react';

const meta: Meta<typeof NeoCodeEditor> = {
  title: 'Editor/NeoCodeEditor',
  component: NeoCodeEditor,
  decorators: [
    (Story) => (
      <NeoProvider config={{ serverUrl: 'http://localhost:8080' }}>
        <Story />
      </NeoProvider>
    ),
  ],
};

export default meta;
type Story = StoryObj<typeof NeoCodeEditor>;

export const JavaScript: Story = {
  args: {
    language: 'javascript',
    value: 'function hello() {\n  console.log("Hello, world!");\n}',
  },
};

export const Python: Story = {
  args: {
    language: 'python',
    value: 'def hello():\n  print("Hello, world!")',
  },
};
