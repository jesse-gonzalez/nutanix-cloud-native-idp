build {
    sources = [
        "source.nutanix.centos7"
    ]

    post-processor "manifest" {
      output = "manifest.json"
      strip_path = true
    }
}
