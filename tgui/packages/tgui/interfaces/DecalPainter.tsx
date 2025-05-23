import { Button, ColorBox, Flex, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type DecalInfo = {
  name: string;
  decal: string;
};

type ColorInfo = {
  name: string;
  color: string;
};

type DirInfo = {
  name: string;
  dir: number;
};

type DecalPainterData = {
  icon_prefix: string;
  decal_list: DecalInfo[];
  color_list: ColorInfo[];
  dir_list: DirInfo[];
  nondirectional_decals: string[];
  supports_custom_color: number;
  current_decal: string;
  current_color: string;
  current_dir: number;
  current_custom_color: string;
};

const filterBoxColor = (color: string) => {
  if (!color.startsWith('#')) {
    return color;
  }

  // cut alpha
  return color.substring(0, 7);
};

export const DecalPainter = (props) => {
  const { act, data } = useBackend<DecalPainterData>();

  const custom_color_selected = !data.color_list.some(
    (color) => color.color === data.current_color,
  );
  const supports_custom_color = !!data.supports_custom_color;

  // Handle custom color icon correctly
  const preview_color = custom_color_selected ? 'custom' : data.current_color;

  const {
    color_list,
    current_custom_color,
    current_color,
    current_decal,
    current_dir,
    decal_list,
    dir_list,
  } = data;

  return (
    <Window width={525} height={400}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section title="Decal Color">
              {color_list.map((color) => {
                return (
                  <Button
                    key={color.color}
                    selected={color.color === current_color}
                    onClick={() =>
                      act('select color', {
                        color: color.color,
                      })
                    }
                  >
                    <ColorBox color={filterBoxColor(color.color)} mr={0.5} />
                    {color.name}
                  </Button>
                );
              })}
              {supports_custom_color && (
                <Button
                  selected={custom_color_selected}
                  onClick={() => act('pick custom color')}
                >
                  <ColorBox color={current_custom_color} mr={0.5} />
                  Custom
                </Button>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Decal Style" fill scrollable>
              <Flex wrap="wrap">
                {decal_list.map((decal) => {
                  const nondirectional = data.nondirectional_decals.includes(
                    decal.decal,
                  );

                  return nondirectional ? (
                    // Tallll button for nondirectional
                    <IconButton
                      key={decal.decal}
                      decal={decal.decal}
                      dir={2}
                      color={preview_color}
                      label={decal.name}
                      selected={decal.decal === current_decal}
                    />
                  ) : (
                    // 4 buttons for directional
                    <Flex key={decal.decal} direction="column">
                      {dir_list.map((dir) => {
                        const selected =
                          decal.decal === current_decal &&
                          dir.dir === current_dir;

                        return (
                          <IconButton
                            key={dir.dir}
                            decal={decal.decal}
                            dir={dir.dir}
                            color={preview_color}
                            label={`${dir.name} ${decal.name}`}
                            selected={selected}
                          />
                        );
                      })}
                    </Flex>
                  );
                })}
              </Flex>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

type IconButtonParams = {
  decal: string;
  dir: number;
  color: string;
  label: string;
  selected: boolean;
};

const IconButton = (props: IconButtonParams) => {
  const { act, data } = useBackend<DecalPainterData>();

  const generateIconKey = (decal: string, dir: number, color: string) =>
    `${data.icon_prefix} ${decal}_${dir}_${color.replace('#', '')}`;

  const icon = generateIconKey(props.decal, props.dir, props.color);

  return (
    <Button
      tooltip={props.label}
      selected={props.selected}
      verticalAlignContent="middle"
      m={'2px'}
      p={1}
      onClick={() =>
        act('select decal', {
          decal: props.decal,
          dir: props.dir,
        })
      }
    >
      <div className={icon} style={{ display: 'block' }} />
    </Button>
  );
};
