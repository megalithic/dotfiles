Vim�UnDo� O��ٮ�f&���9�j��+Q�i�*��H��0�8�   E                                   \Í�    _�                     	        ����                                                                                                                                                                                                                                                                                                                                                             \Í�     �      
          6  public description = 'registed services of coc.nvim'5�_�                     	       ����                                                                                                                                                                                                                                                                                                                                                             \Í�    �       A   3   .   (import { Neovim } from '@chemzqm/neovim'   %import services from '../../services'   3import { ListContext, ListItem } from '../../types'    import BasicList from '../basic'   !import { wait } from '../../util'       5export default class ServicesList extends BasicList {   !  public defaultAction = 'toggle'   8  public description = 'registered services of coc.nvim'     public name = 'services'         constructor(nvim: Neovim) {       super(nvim)       ,    this.addAction('toggle', async item => {         let { id } = item.data         await services.toggle(id)         await wait(100)   '    }, { persist: true, reload: true })     }       F  public async loadItems(_context: ListContext): Promise<ListItem[]> {   *    let stats = services.getServiceStats()       stats.sort((a, b) => {   !      return a.id > b.id ? -1 : 1       })       return stats.map(stat => {   6      let prefix = stat.state == 'running' ? '*' : ' '         return {   X        label: `${prefix}\t${stat.id}\t[${stat.state}]\t${stat.languageIds.join(', ')}`,           data: { id: stat.id }         }       })     }         public doHighlight(): void {       let { nvim } = this       nvim.pauseNotification()   f    nvim.command('syntax match CocServicesPrefix /\\v^./ contained containedin=CocServicesLine', true)   i    nvim.command('syntax match CocServicesName /\\v%3c\\S+/ contained containedin=CocServicesLine', true)   o    nvim.command('syntax match CocServicesStat /\\v\\t\\[\\w+\\]/ contained containedin=CocServicesLine', true)   r    nvim.command('syntax match CocServicesLanguages /\\v(\\])@<=.*$/ contained containedin=CocServicesLine', true)   J    nvim.command('highlight default link CocServicesPrefix Special', true)   E    nvim.command('highlight default link CocServicesName Type', true)   J    nvim.command('highlight default link CocServicesStat Statement', true)   M    nvim.command('highlight default link CocServicesLanguages Comment', true)5��