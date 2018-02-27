# Installation

## MacOS

```
brew install zgulde/zgulde/cods
```

**Updating**

```
brew upgrade cods
cods update
```

## Linux / Other

You'll need to install this manually, luckily, that's not too difficult

1. Clone this repo

    ```
    git clone <this-project> ~/opt/cods
    ```

1. Put the init script on your PATH

    ```
    ln -s ~/opt/cods/bin/init.sh /usr/local/bin/cods # or wherever you prefer
    ```

By default this tool will install commands in to `/usr/local/bin`, but if you
would rather them be somewhere else, you can configure this:

```
cods # The first time it is run it created the configuration file
vim ~/.config/cods/config.sh
```

and change `BIN_PREFIX` to whatever you would prefer

**Updating**

```
cd ~/opt/cods # or wherever you cloned this
git fetch origin

# get the latest
git reset --hard origin/master

# or a specific version
git checkout v0.2.3
```


