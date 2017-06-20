# Return pluginsite elasticsearch index age in hour
#
import urllib2
import json
from datetime import datetime, timedelta
from checks import AgentCheck

class PluginsApiCheck(AgentCheck):
    def check(self,instance):
        metric = 'plugins.index.age'
        site = instance ['site']
        tag = "site:" + site
        self.gauge(metric,self.get_index_age(site),tags=[tag])

    def get_index_age(self, site):
        url = "https://{0}/api/health/elasticsearch".format(site)
        health_status = urllib2.urlopen(url).read()
        index_creation = datetime.strptime(json.loads(health_status)['createdAt'],'%Y-%m-%dT%H:%M:%S')
        age = datetime.today() - index_creation
        return  age.seconds / 3600
