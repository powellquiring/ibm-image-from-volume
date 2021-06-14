# ibm-image-from-volume
Demonstrate image from volume on the ibm clooud

# Steps

- 000 - prerequisites
- 010 - terraform A create initial instance, cloud-init user_data script to initialize a file
- 020 - create an image from the volume
- 030 - terraform B create a new instance from the image created in the previous step
- 040 - verify that the running instance has the initialized file
- 070 - image destroy
- 080 - terraform B destroy
- 090 - terraform A destroy
