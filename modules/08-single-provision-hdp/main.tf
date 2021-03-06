resource "null_resource" "clone_hdp_repo" {
  # Clone HDP repository
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook resources/clone-ansible-hortonworks.yml"
  }
}

locals {

  ambari-host = "${data.consul_keys.app.var.public_dns_ambari}"
  ambari-ip = "${data.consul_keys.app.var.public_ip_ambari}"
  master-host = "${data.consul_keys.app.var.public_dns_namenode}"
  master-ip = "${data.consul_keys.app.var.public_ip_namenode}"
  slave-host = "${data.consul_keys.app.var.public_dns_datanode}"
  slave-ip = "${data.consul_keys.app.var.public_ip_datanode}"

  clustername = "${data.consul_keys.hdp.var.hdp_cluster_name}"
  ambari_version = "${data.consul_keys.hdp.var.ambari_version}"
  hdp_version = "${data.consul_keys.hdp.var.hdp_version}"
  hdp_build_number = "${data.consul_keys.hdp.var.hdp_build_number}"

  master-clients = "${data.consul_keys.hdp.var.master-clients}"
  master-services = "${data.consul_keys.hdp.var.master-services}"
  slave-clients = "${data.consul_keys.hdp.var.master-clients}"
  slave-services = "${data.consul_keys.hdp.var.slave-services}"

  #workdir="${path.cwd}/output/hdp-server/${data.consul_keys.mine.var.hdp_cluster_name}"
}

# prepare hosts file
data "template_file" "ansible_hosts" {
  template = "${file("${path.module}/resources/templates/ansible-hosts.tmpl")}"

  vars {
    master-host = "${local.master-host}"
    master-ip = "${local.master-ip}"
    ansible_hdp_slave_name   = ""
    ansible_hdp_slave_hosts  = ""
    ansible_hdp_slave_login_cred = ""
  }
}

resource "local_file" "ansible_hosts_rendered" {
  content  = "${data.template_file.ansible_hosts.rendered}"
  filename = "${local.workdir}/output/ansible-hosts"
}

# prepare hdp config file
data "template_file" "hdp_config" {
  template = "${file("${path.module}/resources/templates/hdp-cluster-config.tmpl")}"

  vars {
    clustername = "${local.clustername}"
    ambari_version = "${local.ambari_version}"
    hdp_version = "${local.hdp_version}"
    hdp_build_number = "${local.hdp_build_number}"
    master-clients = "${local.master-clients}"
    master-services = "${local.master-services}"
    slave-clients = "${local.master-clients}"
    slave-services = "${local.slave-services}"
  }
}

resource "local_file" "hdp_config_rendered" {
  content  = "${data.template_file.hdp_config.rendered}"
  filename = "${local.workdir}/output/hdp-cluster-config.yml"
}

resource "null_resource" "passwordless_ssh" {
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts ${local.workdir}/resources/passwordless-ssh.yml"
  }
}

resource "null_resource" "install_python_packages" {
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts ${local.workdir}/resources/install-python-packages.yml"
  }
}

resource "null_resource" "prepare_nodes" {
  depends_on = [
    "null_resource.install_python_packages",
    "local_file.ansible_hosts_rendered",
    "local_file.hdp_config_rendered",
  ]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static ${local.workdir}/resources/ansible-hortonworks/playbooks/prepare_nodes.yml"
  }
}

resource "null_resource" "install_ambari" {
  depends_on = ["null_resource.prepare_nodes"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${local.workdir}/resources/ansible-hortonworks/playbooks/install_ambari.yml"
  }
}

resource "null_resource" "configure_ambari" {
  depends_on = ["null_resource.install_ambari"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${local.workdir}/resources/ansible-hortonworks/playbooks/configure_ambari.yml"
  }
}

resource "null_resource" "apply_blueprint" {
  depends_on = ["null_resource.configure_ambari"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${local.workdir}/resources/ansible-hortonworks/playbooks/apply_blueprint.yml"
  }
}

resource "null_resource" "post_install" {
  depends_on = ["null_resource.apply_blueprint"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${local.workdir}/resources/ansible-hortonworks/playbooks/post_install.yml"
  }
}
