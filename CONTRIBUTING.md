# Tips for contributing

## Local development with Vagrant

### Working around jenkins::controller role

When a plugin needs to be added but it doesn't work, you may either install the plugin manually (`vagrant ssh jenkins::controller`) or either destroy the instance (`vagrant destroy jenkins::controller`) and restart from scratch.
