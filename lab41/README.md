# Lab 41

Create am instance and role allowing s3 read access.

```bash
$ terraform apply
$ ssh -i <key> ubuntu@<ip>
ubuntu@<ip>:~$ aws s3 ls  --region eu-central-1 s3://lab41-bucket/
```
