#!/usr/bin/env python
import sys
from zabbix.api import ZabbixAPI

url  = "your-zabbix-server-api-url"
user = "your-zabbix-api-user"
password = "your-zabbix-api-user-password"

zapi = ZabbixAPI(url=url, user=user, password=password)
res1 = zapi.do_request('host.get', { 'filter': {'name': sys.argv[1]}, 'output': 'hostid'})
res2 = str(res1.get(u'result')).split('\'')
zabbix_hostid = res2[3]
zapi.do_request('host.update', {'hostid': zabbix_hostid, 'tls_connect': 4, 'tls_accept': 4 })

