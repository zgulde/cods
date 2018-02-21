# Installation

## MacOS

```
brew install zgulde/zgulde/cods
```

**Updating**

```
brew upgrade cods
```

## Other

You'll need to install this manually, luckily, that's not too difficult

1. Clone this repo

    ```
    git clone <this-project> ~/opt/cods
    ```

1. Put the init script on your PATH

    ```
    ln -s ~/opt/cods/bin/init.sh /usr/local/bin/cods
    ```

**Updating**

```
cd ~/opt/cods
git pull origin master
```
