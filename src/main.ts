import 'the-new-css-reset';

import { clock } from './core/clock';
import { renderer } from './core/renderer';
import { sizes } from './core/sizes';
import { TexRefraction } from './tex-refraction';

sizes.addEventListener('resize', resize);
clock.addEventListener('tick', update);

const texRefraction = new TexRefraction();
renderer.scene.add(texRefraction.mesh);

function resize() {
  renderer.resize();
}

function update() {
  texRefraction.update();
  renderer.update();
}
