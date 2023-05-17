import * as THREE from 'three';

import { clock } from '../core/clock';
import { sizes } from '../core/sizes';
import fragmentShader from './fragment.glsl';
import tex from './rain.jpg';
import vertexShader from './vertex.glsl';

const geometry = new THREE.PlaneGeometry(2, 2, 1, 1);

const resolution = new THREE.Vector2(
  sizes.width * sizes.pixelRatio,
  sizes.height * sizes.pixelRatio,
);
const mouse = new THREE.Vector2();
window.addEventListener('mousemove', ({ clientX, clientY }) => {
  mouse.x = (clientX / sizes.width) * 2 - 1;
  mouse.y = -(clientY / sizes.height) * 2 + 1;
});
window.addEventListener(
  'touchmove',
  (e) => {
    e.preventDefault();
    mouse.x = (e.touches[0].clientX / sizes.width) * 2 - 1;
    mouse.y = -(e.touches[0].clientY / sizes.height) * 2 + 1;
  },
  {
    passive: false,
  },
);

export class TexRefraction {
  public readonly mesh: THREE.Mesh;
  private material: THREE.ShaderMaterial;
  private abortController = new AbortController();
  constructor() {
    this.material = new THREE.ShaderMaterial({
      vertexShader,
      fragmentShader,
      uniforms: {
        uTime: { value: clock.elapsed },
        uMouse: { value: mouse },
        uResolution: { value: resolution },
        uTexture: { value: new THREE.TextureLoader().load(tex) },
      },
    });
    this.mesh = new THREE.Mesh(geometry, this.material);
    sizes.addEventListener(
      'resize',
      () => {
        resolution.x = sizes.width * sizes.pixelRatio;
        resolution.y = sizes.height * sizes.pixelRatio;
      },
      {
        signal: this.abortController.signal,
      },
    );
  }

  public update() {
    this.material.uniforms.uTime.value = clock.elapsed;
  }

  public dispose() {
    this.material.dispose();
    this.abortController.abort();
  }
}
