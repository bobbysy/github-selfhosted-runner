Build using the following:

```
docker build -t nvcr.io/nvidia/cuda:12.2.0-devel-ubuntu20.04-custom --secret id=mysecret,src=.env .
```